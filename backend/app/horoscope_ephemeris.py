"""Lahiri Moon positions and city daylight for horoscope calculations."""

from __future__ import annotations

from datetime import date, datetime, timedelta, timezone
from functools import lru_cache
from math import asin, atan2, cos, degrees, radians, sin
from threading import RLock
from typing import NamedTuple

IST = timezone(timedelta(hours=5, minutes=30), name="IST")
UTC = timezone.utc
J2000 = datetime(2000, 1, 1, 12, tzinfo=UTC)
UNIX_EPOCH = datetime(1970, 1, 1, tzinfo=UTC)
JULIAN_UNIX_EPOCH = 2440587.5
LIBRARY_LOCK = RLock()


class Sample(NamedTuple):
    sign: int
    nakshatra: int
    waxing: bool


class Transit(NamedTuple):
    first: int
    last: int
    ingress: datetime | None


def _sin(angle: float) -> float:
    return sin(radians(angle % 360))


def _sun(t: float) -> float:
    mean = 280.46646 + t * (36000.76983 + 0.0003032 * t)
    anomaly = 357.52911 + t * (35999.05029 - 0.0001537 * t)
    correction = (
        (1.914602 - t * (0.004817 + 0.000014 * t)) * _sin(anomaly)
        + (0.019993 - 0.000101 * t) * _sin(2 * anomaly)
        + 0.000289 * _sin(3 * anomaly)
    )
    return (mean + correction) % 360


class MeeusEphemeris:
    name = "Meeus / approximate Lahiri"
    key = "meeus-lahiri"

    def __init__(self, moon_terms: list[list[int]]) -> None:
        self._terms = tuple(tuple(term) for term in moon_terms)

    def longitudes(self, time_utc: datetime) -> tuple[float, float]:
        # Meeus chapters 25 and 47, mean ecliptic/equinox of date.
        # TT is approximately 69.184 seconds ahead of present-day civil UTC.
        t = ((time_utc - J2000).total_seconds() + 69.184) / (86400 * 36525)
        mean = (218.3164477 + t * (481267.88123421 +
                t * (-0.0015786 + t * (1 / 538841 - t / 65194000)))) % 360
        elongation = (297.8501921 + t * (445267.1114034 +
                      t * (-0.0018819 + t * (1 / 545868 - t / 113065000)))) % 360
        solar_anomaly = (357.5291092 + t * (35999.0502909 +
                         t * (-0.0001536 + t / 24490000))) % 360
        lunar_anomaly = (134.9633964 + t * (477198.8675055 +
                         t * (0.0087414 + t * (1 / 69699 - t / 14712000)))) % 360
        latitude_arg = (93.2720950 + t * (483202.0175233 +
                        t * (-0.0036539 + t * (-1 / 3526000 + t / 863310000)))) % 360
        eccentricity = 1 - t * (0.002516 + 0.0000074 * t)
        correction = (
            3958 * _sin(119.75 + 131.849 * t)
            + 1962 * _sin(mean - latitude_arg)
            + 318 * _sin(53.09 + 479264.29 * t)
        )
        for d, m, mp, f, coefficient in self._terms:
            phase = d * elongation + m * solar_anomaly + mp * lunar_anomaly + f * latitude_arg
            correction += coefficient * eccentricity ** abs(m) * _sin(phase)
        ayanamsa = 23 + 51 / 60 + (25.532 + t * (5028.796195 + 1.1054348 * t)) / 3600
        return (_sun(t) - ayanamsa) % 360, (mean + correction / 1_000_000 - ayanamsa) % 360

    def daylight(
        self, start: datetime, latitude: float, longitude: float,
    ) -> tuple[datetime, datetime] | None:
        # Standard apparent rise/set, sea level, geometric center at -0.833°.
        lat = radians(latitude)

        def altitude(instant: datetime) -> float:
            days = (instant - J2000).total_seconds() / 86400
            t = days / 36525
            solar = radians(_sun(t))
            obliquity = radians(23.439291 - 0.0130042 * t)
            ra = atan2(cos(obliquity) * sin(solar), cos(solar))
            dec = asin(sin(obliquity) * sin(solar))
            gst = (280.46061837 + 360.98564736629 * days +
                   t * t * (0.000387933 - t / 38710000)) % 360
            hour = radians(gst + longitude) - ra
            sine = sin(lat) * sin(dec) + cos(lat) * cos(dec) * cos(hour)
            return degrees(asin(max(-1.0, min(1.0, sine)))) + 0.833

        def crossing(low: datetime, high: datetime, rising: bool) -> datetime:
            while high - low > timedelta(seconds=1):
                midpoint = low + (high - low) / 2
                if (altitude(midpoint) >= 0) == rising:
                    high = midpoint
                else:
                    low = midpoint
            return high

        previous = start
        height = altitude(previous)
        sunrise = None
        for hour in range(1, 25):
            current = start + timedelta(hours=hour)
            next_height = altitude(current)
            if sunrise is None and height < 0 <= next_height:
                sunrise = crossing(previous, current, True)
            if sunrise is not None and height > 0 >= next_height:
                return sunrise, crossing(previous, current, False)
            previous, height = current, next_height
        return None


class SwissEphemeris:
    name = "Swiss Ephemeris · Lahiri (Moshier)"
    key = "swiss-lahiri-moshier"

    def __init__(self) -> None:
        try:
            import swisseph
        except ImportError as error:
            raise RuntimeError("HOROSCOPE_EPHEMERIS=swiss requires pyswisseph") from error
        self.swe = swisseph

    @staticmethod
    def _julian(instant: datetime) -> float:
        return JULIAN_UNIX_EPOCH + (instant - UNIX_EPOCH).total_seconds() / 86400

    def longitudes(self, time_utc: datetime) -> tuple[float, float]:
        swe = self.swe
        flags = swe.FLG_MOSEPH | swe.FLG_SIDEREAL
        jd = self._julian(time_utc)
        with LIBRARY_LOCK:
            swe.set_sid_mode(swe.SIDM_LAHIRI)
            sun, _ = swe.calc_ut(jd, swe.SUN, flags)
            moon, _ = swe.calc_ut(jd, swe.MOON, flags)
        return sun[0] % 360, moon[0] % 360

    def daylight(
        self, start: datetime, latitude: float, longitude: float,
    ) -> tuple[datetime, datetime] | None:
        swe = self.swe
        jd = self._julian(start)
        location = (longitude, latitude, 0)
        with LIBRARY_LOCK:
            status, rise = swe.rise_trans(jd, swe.SUN, swe.CALC_RISE, location,
                                          0, 15, swe.FLG_MOSEPH)
            if status != 0 or rise[0] >= jd + 1:
                return None
            status, setting = swe.rise_trans(rise[0], swe.SUN, swe.CALC_SET, location,
                                             0, 15, swe.FLG_MOSEPH)
        if status != 0 or not rise[0] < setting[0] < jd + 1:
            return None
        return tuple(UNIX_EPOCH + timedelta(days=value - JULIAN_UNIX_EPOCH)
                     for value in (rise[0], setting[0]))


def day_start(day: date) -> datetime:
    return datetime(day.year, day.month, day.day, tzinfo=IST).astimezone(UTC)


@lru_cache(maxsize=128)
def samples(ephemeris, day: date) -> tuple[Sample, ...]:
    result = []
    for minute in (9 * 60, 14 * 60 + 30, 19 * 60 + 30):
        sun, moon = ephemeris.longitudes(day_start(day) + timedelta(minutes=minute))
        result.append(Sample(int(moon // 30), min(26, int(moon / (360 / 27))),
                             (moon - sun) % 360 < 180))
    return tuple(result)


@lru_cache(maxsize=128)
def transit(ephemeris, day: date) -> Transit:
    def sign_at(instant: datetime) -> int:
        return int(ephemeris.longitudes(instant)[1] // 30)

    low = day_start(day)
    high = low + timedelta(days=1, microseconds=-1)
    start, end = sign_at(low), sign_at(high)
    if start == end:
        return Transit(start, end, None)
    while high - low > timedelta(seconds=1):
        mid = low + (high - low) / 2
        if sign_at(mid) == start:
            low = mid
        else:
            high = mid
    return Transit(start, end, high)
