"""
Cache-first access to Gemini-generated horoscope and panchang readings.

Every Gemini call in the app goes through here so the free-tier quota is
respected no matter who triggers it:

- `gemini_limiter` caps ALL Gemini calls (users + precache) per minute.
- `precache_pacer` additionally caps the nightly precache, so users always keep
  the remaining share of the quota.
- Concurrent requests for the same reading share one Gemini call.
- Only real AI output is stored; parse-failure fallbacks are served but not cached.
"""
import asyncio
import logging
import os
import time
from collections import deque
from typing import Any, Awaitable, Callable, Dict, Optional, Tuple

from app.database import (
    get_cached_horoscope,
    save_cached_horoscope,
    get_cached_panchang,
    save_cached_panchang,
    increment_api_stat,
)
from app.gemini_service import generate_horoscope, generate_panchang

logger = logging.getLogger("bhaktidhara.vedic_cache")


def _env_int(name: str, default: int) -> int:
    try:
        return max(1, int(os.getenv(name, str(default))))
    except ValueError:
        return default


GEMINI_RPM = _env_int("GEMINI_RPM", 10)
# Precache must leave at least one call per minute for real users.
PRECACHE_RPM = min(_env_int("PRECACHE_RPM", 5), max(1, GEMINI_RPM - 1))
# The app gives up on the backend after 5s, so don't queue users for long.
USER_WAIT_SECONDS = float(os.getenv("GEMINI_USER_WAIT_SECONDS", "3"))
USER_MAX_WAIT_SECONDS = 30.0
MAX_BACKGROUND_JOBS = 50


class GeminiBusy(Exception):
    """Raised when no Gemini slot is free for a user request right now."""


class SlidingWindowLimiter:
    """Allows at most `limit` acquisitions in any rolling `window` seconds."""

    def __init__(self, limit: int, window: float = 60.0):
        self.limit = limit
        self.window = window
        self._calls: deque = deque()
        self._lock = asyncio.Lock()

    def _prune(self, now: float):
        while self._calls and now - self._calls[0] >= self.window:
            self._calls.popleft()

    def used(self) -> int:
        self._prune(time.monotonic())
        return len(self._calls)

    async def acquire(self, timeout: Optional[float] = None) -> bool:
        """Waits for a free slot. Returns False if `timeout` seconds pass first."""
        deadline = None if timeout is None else time.monotonic() + timeout
        while True:
            async with self._lock:
                now = time.monotonic()
                self._prune(now)
                if len(self._calls) < self.limit:
                    self._calls.append(now)
                    return True
                wait = self._calls[0] + self.window - now
            if deadline is not None:
                remaining = deadline - time.monotonic()
                if remaining <= 0:
                    return False
                wait = min(wait, remaining)
            await asyncio.sleep(max(wait, 0.05))


gemini_limiter = SlidingWindowLimiter(GEMINI_RPM)
precache_pacer = SlidingWindowLimiter(PRECACHE_RPM)

_inflight: Dict[Tuple, "asyncio.Task[Dict[str, Any]]"] = {}


def limiter_status() -> Dict[str, Any]:
    return {
        "gemini_rpm": GEMINI_RPM,
        "precache_rpm": PRECACHE_RPM,
        "gemini_calls_last_minute": gemini_limiter.used(),
        "inflight": len(_inflight),
    }


def _start(key: Tuple, factory: Callable[[], Awaitable[Dict[str, Any]]]) -> "asyncio.Task[Dict[str, Any]]":
    task = asyncio.create_task(factory())
    _inflight[key] = task
    task.add_done_callback(lambda _t: _inflight.pop(key, None))
    return task


async def _generate_and_save(
    generate: Callable[[], Awaitable[Dict[str, Any]]],
    save: Callable[[Dict[str, Any]], Awaitable[None]],
    stat: str,
) -> Dict[str, Any]:
    try:
        data = await generate()
    except Exception:
        await increment_api_stat("gemini_error")
        raise
    if data.get("isAiGenerated"):
        await save(data)
    await increment_api_stat(stat)
    return data


async def _resolve(
    key: Tuple,
    lookup: Callable[[], Awaitable[Optional[Dict[str, Any]]]],
    generate: Callable[[], Awaitable[Dict[str, Any]]],
    save: Callable[[Dict[str, Any]], Awaitable[None]],
    stat: str,
    force_refresh: bool,
) -> Tuple[Dict[str, Any], str]:
    """User path: cache → join an in-flight call → call Gemini if a slot is free."""
    if not force_refresh:
        cached = await lookup()
        if cached:
            return cached, "cache"

    task = _inflight.get(key)
    if task is None:
        if not await gemini_limiter.acquire(timeout=USER_WAIT_SECONDS):
            _queue_background(key, generate, save, stat)
            await increment_api_stat("gemini_busy")
            raise GeminiBusy("Gemini quota is busy, please retry shortly")
        task = _inflight.get(key) or _start(key, lambda: _generate_and_save(generate, save, stat))

    # shield: a client disconnect or timeout must not cancel a generation others share.
    try:
        data = await asyncio.wait_for(asyncio.shield(task), timeout=USER_MAX_WAIT_SECONDS)
    except asyncio.TimeoutError:
        raise GeminiBusy("Reading is still being generated, please retry shortly")
    return data, "gemini_generated"


def _queue_background(key, generate, save, stat):
    """Generates a busy-rejected reading once a slot frees up, so the next request hits cache."""
    if key in _inflight or len(_inflight) >= MAX_BACKGROUND_JOBS:
        return

    async def run():
        await gemini_limiter.acquire()
        return await _generate_and_save(generate, save, stat)

    task = _start(key, run)
    task.add_done_callback(lambda t: t.cancelled() or t.exception())


# ── Public helpers ───────────────────────────────────────────────────────────

async def get_or_create_horoscope(
    date_str: str, rashi_id: str, rashi_name: str, period: str, lang: str, force_refresh: bool = False,
) -> Tuple[Dict[str, Any], str]:
    key = ("horoscope", date_str, rashi_id, period, lang)
    return await _resolve(
        key,
        lookup=lambda: get_cached_horoscope(date_str, rashi_id, period, lang),
        generate=lambda: generate_horoscope(
            rashi_name=rashi_name, period=period, lang_code=lang, date_text=date_str, rashi_id=rashi_id
        ),
        save=lambda data: save_cached_horoscope(date_str, rashi_id, period, lang, data),
        stat="horoscope_gemini",
        force_refresh=force_refresh,
    )


async def get_or_create_panchang(
    date_str: str, city_id: str, city_name: str, lang: str, force_refresh: bool = False,
) -> Tuple[Dict[str, Any], str]:
    key = ("panchang", date_str, city_id, lang)
    return await _resolve(
        key,
        lookup=lambda: get_cached_panchang(date_str, city_id, lang),
        generate=lambda: generate_panchang(city_name=city_name, date_str=date_str, lang_code=lang),
        save=lambda data: save_cached_panchang(date_str, city_id, lang, data),
        stat="panchang_gemini",
        force_refresh=force_refresh,
    )


async def precache_item(
    key: Tuple,
    lookup: Callable[[], Awaitable[Optional[Dict[str, Any]]]],
    generate: Callable[[], Awaitable[Dict[str, Any]]],
    save: Callable[[Dict[str, Any]], Awaitable[None]],
) -> str:
    """
    Precache path. Returns "cached" if a user already generated it (no Gemini call
    spent), "generated" on success, or "fallback" if Gemini output wasn't usable.
    """
    if await lookup():
        return "cached"
    if key in _inflight:
        await asyncio.shield(_inflight[key])
        return "cached"

    await precache_pacer.acquire()
    # A user may have generated it while we waited for the precache budget.
    if await lookup():
        return "cached"
    if key in _inflight:
        await asyncio.shield(_inflight[key])
        return "cached"

    await gemini_limiter.acquire()
    task = _inflight.get(key) or _start(key, lambda: _generate_and_save(generate, save, "precache_gemini"))
    data = await asyncio.shield(task)
    return "generated" if data.get("isAiGenerated") else "fallback"
