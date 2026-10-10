import csv
import re

def format_views(v_str):
    try:
        v = int(v_str.strip())
        if v >= 1_000_000_000:
            val = v / 1_000_000_000
            return f'{val:.1f}B views'.replace('.0B', 'B')
        elif v >= 1_000_000:
            val = v / 1_000_000
            return f'{val:.1f}M views'.replace('.0M', 'M')
        elif v >= 1_000:
            val = v / 1_000
            return f'{val:.0f}K views'
        else:
            return f'{v} views'
    except Exception:
        return 'Popular'

def escape_dart_str(s):
    s = s.replace('\r', ' ').replace('\n', ' ')
    s = s.replace('\\', '\\\\')
    s = s.replace('"', '\\"')
    s = s.replace('$', '\\$')
    return s.strip()

# ==========================================
# 1. RADHA RANI SONGS CATALOG
# ==========================================

r_rows = list(csv.DictReader(open('scratch/radha_songs.csv', encoding='utf-8')))

def clean_radha_artist(channel, title, vtitle, note):
    ch = channel.replace(' - Topic', '').replace(' Official', '').strip()
    comb = f'{title} {vtitle} {note} {channel}'.lower()

    known = [
        'Hansraj Raghuwanshi', 'Simpal Kharel', 'B Praak', 'Indresh Upadhyay',
        'Sadhvi Purnima', 'Tripty Shakya', 'Chitra Vichitra', 'Devi Neha Saraswat',
        'Jaya Kishori', 'Devi Chitralekha', 'Swasti Mehul', 'Gaurav Krishna Goswami',
        'Pawan Singh', 'Kripalu Ji Maharaj', 'Afsana Khan', 'Radhika Das',
        'Harinam Das', 'Charanjeet Singh Sondhi', 'Prakash Das', 'Dheeraj Bawra',
        'Saurabh Sahu', 'Mohit Lalwani', 'Paras Chhabra', 'Master Rana', 'Shubhangi Gaikwad',
        'Aniket Maharaj Patil', 'Tarun Sagar', 'Nandlal Chhanga', 'Pooja Brajwasi',
        'Pooja Sakhi', 'Satendra Gurjar'
    ]
    for k in known:
        if k.lower() in comb:
            return k

    m = re.search(r'\((.*?)\)', title)
    if m:
        cand = m.group(1).split(',')[0].strip()
        bad = ['shyam ji ka lifafa', 'radhakrishn tv serial', 'haryanvi', 'kirtan', 'braj rasiya', 'bengali folk', 'rajasthani', 'marathi gavlan', 'jain']
        if not any(b in cand.lower() for b in bad) and len(cand) > 3 and len(cand) < 28:
            return cand

    return ch

def radha_category(row):
    rank = int(row['rank'])
    title = row['title'].lower()
    vtitle = row.get('videoTitle', '').lower()
    note = row.get('note', '').lower()
    comb = f'{title} {vtitle} {note}'

    if any(k in comb for k in ['gavlan', 'folk', 'rasiya', 'haryanvi', 'rajasthani', 'gujarati', 'bengali']):
        return 'Braj Rasiya & Folk'
    if any(k in comb for k in ['kirtan', 'jaap', 'jap', 'naam ras', 'sumiran', 'ratte', 'naam ki mala', 'bolo radhe']):
        return 'Kirtan & Naam Jaap'
    if any(k in comb for k in ['barsan', 'kishori', 'ladli', 'vrindavan', 'thakurani', 'albeli']):
        return 'Barsane Ki Kishori'
    if rank <= 12:
        return 'Popular & Trending'
    return 'Radhe Krishna Bhajan'

def radha_duration(row, cat):
    comb = f"{row['title']} {row.get('videoTitle', '')} {row.get('note', '')}".lower()
    if 'kirtan' in comb or 'sankirtan' in comb:
        return '11:20'
    if 'serial' in comb:
        return '4:15'
    if cat == 'Kirtan & Naam Jaap':
        return '8:45'
    if cat == 'Braj Rasiya & Folk':
        return '5:10'
    return '5:35'

radha_code = '''import '../../domain/entities/devotional_song_item.dart';

/// Curated catalog of 100 YouTube-embeddable Radha Rani (Shri Radha / Kishori Ji / Barsane Wali)
/// bhajans, kirtans, and Braj devotional songs ranked by popularity.
const List<DevotionalSongItem> kRadhaSongsCatalog = [
'''

for r in r_rows:
    rank = int(r['rank'])
    title = r['title'].strip()
    vid = r['videoId'].strip()
    vtitle = r['videoTitle'].strip()
    channel = r['channel'].strip()
    views = r['views'].strip()
    note = r.get('note', '').strip()

    artist = clean_radha_artist(channel, title, vtitle, note)
    cat = radha_category(r)
    dur = radha_duration(r, cat)

    id_str = f'radha_yt_{rank:02d}' if rank < 100 else f'radha_yt_{rank}'
    radha_code += f'''  DevotionalSongItem(
    id: '{id_str}',
    song: "{escape_dart_str(title)}",
    artist: "{escape_dart_str(artist)}",
    videoId: '{vid}',
    videoTitle: "{escape_dart_str(vtitle)}",
    channel: "{escape_dart_str(channel)}",
    category: '{cat}',
    durationText: '{dur}',
    viewsText: '{format_views(views)}',
  ),
'''

radha_code += '];\n'

with open('lib/data/datasources/radha_songs_catalog.dart', 'w', encoding='utf-8') as f:
    f.write(radha_code)

print(f'Generated lib/data/datasources/radha_songs_catalog.dart with {len(r_rows)} items.')


# ==========================================
# 2. GAYATRI MATA SONGS CATALOG
# ==========================================

g1 = list(csv.DictReader(open('scratch/gayatri_section1.csv', encoding='utf-8')))
g2 = list(csv.DictReader(open('scratch/gayatri_section2.csv', encoding='utf-8')))

def clean_gayatri_artist(channel, title, vtitle, note):
    ch = channel.replace(' - Topic', '').replace(' Official', '').strip()
    comb = f'{title} {vtitle} {note} {channel}'.lower()

    if 'pranit' in ch.lower():
        return 'Gayatri Pariwar'

    known = [
        'Anuradha Paudwal', 'Hemant Chauhan', 'Ishita Vishwakarma', 'Avani Prajapati',
        'Avinash Karn', 'Parthiv Gohil', 'Ruchita Prajapati', 'Mukesh',
        'Brahmasri Vaddiparti Padmakar', 'Sri K. Suresh', 'Kamlesh Thakur',
        'Satya Prakash Adhikari', 'Kuruvada Sisters', 'Manasi Patra', 'Pragya Sharma',
        'Aniket Khandekar', 'Sangeeta Dave'
    ]
    for k in known:
        if k.lower() in comb:
            return k

    m = re.search(r'\((.*?)\)', title)
    if m:
        cand = m.group(1).split(',')[0].strip()
        bad = [
            'gujarati', 'odia', 'telugu', 'marathi', 'kannada', 'aarti', 'film',
            'gayatri mahima', 'om bhur bhuva swaha', 'ayatu varade devi',
            'vedmata gayatri', 'gayatri stavan'
        ]
        if not any(b in cand.lower() for b in bad) and len(cand) > 3 and len(cand) < 28:
            return cand

    if 'shantikunj' in ch.lower() or 'awgp' in ch.lower():
        return 'Shantikunj Haridwar'

    return ch

def gayatri_category(row, is_s1):
    t = row.get('type', '').lower()
    title = row['title'].lower()
    vtitle = row.get('videoTitle', '').lower()
    note = row.get('note', '').lower()
    comb = f'{title} {vtitle} {note}'

    if is_s1:
        if t == 'chalisa' or 'chalisa' in comb:
            return 'Aarti & Chalisa'
        if t == 'mantra' or any(k in comb for k in ['mantra', 'avahanam', 'vimochanam']):
            return 'Gayatri Mantra & Jaap'
        return 'Stotram & Kavacham'
    else:
        if any(k in comb for k in ['aarti', 'aarati', 'harathi']):
            return 'Aarti & Chalisa'
        if any(k in comb for k in ['jap lo', 'mahamantra']):
            return 'Gayatri Mantra & Jaap'
        if int(row['rank']) <= 5:
            return 'Popular & Trending'
        return 'Pragya Geet & Bhajan'

def gayatri_duration(row, cat):
    comb = f"{row['title']} {row.get('videoTitle', '')} {row.get('note', '')}".lower()
    if '108' in comb:
        return '22:30'
    if 'amritwani' in comb or 'amrit dhara' in comb or 'sahasranama' in comb:
        return '16:00'
    if 'shatak' in comb or 'shaktipath' in comb:
        return '18:45'
    if cat == 'Aarti & Chalisa':
        return '5:15'
    if cat == 'Gayatri Mantra & Jaap':
        return '10:20'
    return '5:40'

gayatri_code = '''import '../../domain/entities/devotional_song_item.dart';

/// Curated catalog of 53 YouTube-embeddable Goddess Gayatri (Vedmata / AWGP Shantikunj / Gayatri Pariwar)
/// mantras, stotras, chalisas, aartis, and Pragya geets ranked by popularity.
const List<DevotionalSongItem> kGayatriSongsCatalog = [
'''

g_idx = 1

# Section 1: 17 Mantras & Stotras
for r in g1:
    title = r['title'].strip()
    vid = r['videoId'].strip()
    vtitle = r['videoTitle'].strip()
    channel = r['channel'].strip()
    views = r['views'].strip()
    note = r.get('note', '').strip()

    artist = clean_gayatri_artist(channel, title, vtitle, note)
    cat = gayatri_category(r, True)
    dur = gayatri_duration(r, cat)

    id_str = f'gayatri_yt_{g_idx:02d}' if g_idx < 100 else f'gayatri_yt_{g_idx}'
    gayatri_code += f'''  DevotionalSongItem(
    id: '{id_str}',
    song: "{escape_dart_str(title)}",
    artist: "{escape_dart_str(artist)}",
    videoId: '{vid}',
    videoTitle: "{escape_dart_str(vtitle)}",
    channel: "{escape_dart_str(channel)}",
    category: '{cat}',
    durationText: '{dur}',
    viewsText: '{format_views(views)}',
  ),
'''
    g_idx += 1

# Section 2: 36 Aartis & Pragya Geet / Bhajans
for r in g2:
    title = r['title'].strip()
    vid = r['videoId'].strip()
    vtitle = r['videoTitle'].strip()
    channel = r['channel'].strip()
    views = r['views'].strip()
    note = r.get('note', '').strip()

    artist = clean_gayatri_artist(channel, title, vtitle, note)
    cat = gayatri_category(r, False)
    dur = gayatri_duration(r, cat)

    id_str = f'gayatri_yt_{g_idx:02d}' if g_idx < 100 else f'gayatri_yt_{g_idx}'
    gayatri_code += f'''  DevotionalSongItem(
    id: '{id_str}',
    song: "{escape_dart_str(title)}",
    artist: "{escape_dart_str(artist)}",
    videoId: '{vid}',
    videoTitle: "{escape_dart_str(vtitle)}",
    channel: "{escape_dart_str(channel)}",
    category: '{cat}',
    durationText: '{dur}',
    viewsText: '{format_views(views)}',
  ),
'''
    g_idx += 1

gayatri_code += '];\n'

with open('lib/data/datasources/gayatri_songs_catalog.dart', 'w', encoding='utf-8') as f:
    f.write(gayatri_code)

print(f'Generated lib/data/datasources/gayatri_songs_catalog.dart with {g_idx - 1} items.')
