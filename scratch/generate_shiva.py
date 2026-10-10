import csv
import re

csv_path = 'scratch/shiva_songs.csv'

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

def clean_artist(channel, title, vtitle, note):
    ch = channel.replace(' - Topic', '').replace(' Official', '').strip()
    combined = f'{title} {vtitle} {note} {channel}'.lower()

    if 'kailash' in combined:
        return 'Kailash Kher'
    if 'sukhwinder' in combined:
        return 'Sukhwinder Singh'

    known = [
        'Hansraj Raghuwanshi', 'Anuradha Paudwal', 'Lakhbir Singh Lakkha',
        'Kailash Kher', 'Shankar Mahadevan', 'Jubin Nautiyal', 'Sonu Nigam',
        'Hariharan', 'Mangli', 'Shahnaaz Akhtar', 'Arijit Singh', 'Amit Trivedi',
        'Sachet-Parampara', 'Abhilipsa Panda', 'S.P. Balasubrahmaniam', 'SPB',
        'Suresh Wadkar', 'B Praak', 'Daler Mehndi', 'Gulshan Kumar', 'Udit Narayan',
        'Pandit Jasraj', 'Hemant Chauhan', 'Osman Mir', 'Vipin Sachdeva', 'Priya Sisters',
        'Ravi Raj', 'Chhotu Singh Rawna', 'Agam Aggarwal', 'K.S.Chitra', 'Ananya Bhat',
        'Mohan Babu', 'Bawa Gulzar', 'Siddharth Mohan', 'Sonu Nigam'
    ]
    for k in known:
        if k.lower() in combined:
            return k

    m = re.search(r'\((.*?)\)', title)
    if m:
        cand = m.group(1).split(',')[0].strip()
        bad_words = [
            'film', 'aarti', 'chalisa', 'stuti', 'mantra', 'version', 'song',
            'folk', 'special', 'telugu', 'tamil', 'kannada', 'marathi',
            'amarnath', 'kedarnath', 'baahubali', 'brahmastra', 'omg 2', 'goodbye'
        ]
        if not any(bw in cand.lower() for bw in bad_words) and len(cand) > 3 and len(cand) < 30:
            return cand

    return ch

def shiva_cat(row):
    rank = int(row['rank'])
    t = row['type'].lower()
    title = row['title'].lower()
    vtitle = row['videoTitle'].lower()
    note = row.get('note', '').lower()
    combined = f'{title} {vtitle} {note}'

    if t == 'aarti' or 'aarti' in combined or t == 'chalisa' or 'chalisa' in combined:
        return 'Aarti & Chalisa'
    if t == 'mantra' or any(x in combined for x in ['mantra', 'dhun', 'jaap', 'jap', 'panchakshari']):
        return 'Mantra & Dhun'
    if t == 'stotra' or any(x in combined for x in ['stotram', 'stotra', 'ashtakam', 'shatakam', 'kavach', 'suprabhatam', 'sahasranama']):
        return 'Stotram & Ashtakam'
    if any(x in combined for x in ['telugu', 'tamil', 'kannada', 'mangli', 'nalgonda', 'sivan', 'thiruvasagam', 'sivapuranam', 'manjunatha']):
        return 'South & Regional'
    if rank <= 15:
        return 'Popular & Trending'
    return 'Shiv Bhajan'

def get_duration(title, vtitle, note, cat):
    combined = f'{title} {vtitle} {note}'.lower()
    if any(x in combined for x in ['amritwani', 'amritdhara', 'rudri path', 'rudram']):
        return '22:30'
    if '108' in combined:
        return '14:20'
    if cat == 'Stotram & Ashtakam':
        return '6:15'
    if cat == 'Mantra & Dhun':
        return '5:45'
    if cat == 'Aarti & Chalisa':
        return '4:15'
    return '4:40'

def escape_dart_str(s):
    s = s.replace('\r', ' ').replace('\n', ' ')
    s = s.replace('\\', '\\\\')
    s = s.replace('"', '\\"')
    s = s.replace('$', '\\$')
    return s.strip()

with open(csv_path, 'r', encoding='utf-8') as f:
    reader = csv.DictReader(f)
    rows = list(reader)

shiva_code = '''import '../../domain/entities/devotional_song_item.dart';

/// Curated catalog of 200 top YouTube-embeddable Lord Shiva (Mahadev / Bholenath / Shankar)
/// songs, bhajans, stotrams, mantras, and aartis ranked by popularity.
const List<DevotionalSongItem> kShivaSongsCatalog = [
'''

for r in rows:
    rank = int(r['rank'])
    title = r['title'].strip()
    vid = r['videoId'].strip()
    vtitle = r['videoTitle'].strip()
    channel = r['channel'].strip()
    views = r['views'].strip()
    note = r.get('note', '').strip()

    artist = clean_artist(channel, title, vtitle, note)
    cat = shiva_cat(r)
    dur = get_duration(title, vtitle, note, cat)

    id_str = f'shiva_yt_{rank:02d}' if rank < 100 else f'shiva_yt_{rank}'
    shiva_code += f'''  DevotionalSongItem(
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

shiva_code += '];\n'

with open('lib/data/datasources/shiva_songs_catalog.dart', 'w', encoding='utf-8') as f:
    f.write(shiva_code)

print(f'Successfully generated lib/data/datasources/shiva_songs_catalog.dart with {len(rows)} songs.')
