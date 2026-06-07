import json
import os
import glob
import csv

def clean_url(url):
    if not url:
        return ""
    # Strip {verifycache} prefix if present
    if url.startswith("{verifycache}"):
        return url[len("{verifycache}"):]
    return url

def find_latest_file(pattern):
    files = glob.glob(pattern)
    if not files:
        return None
    # Sort files by modification time (newest first)
    files.sort(key=os.path.getmtime, reverse=True)
    return files[0]

def load_csv_rows(csv_path):
    if not os.path.exists(csv_path):
        print(f"Warning: CSV file not found: {csv_path}")
        return []
    with open(csv_path, "r", encoding="utf-8") as f:
        reader = csv.reader(f)
        rows = list(reader)
    if not rows:
        return []
    # Strip whitespace from headers
    headers = [h.strip() for h in rows[0]]
    results = []
    for r in rows[1:]:
        if not r:
            continue
        row_dict = {}
        for idx, h in enumerate(headers):
            val = r[idx] if idx < len(r) else ""
            row_dict[h] = val
        results.append(row_dict)
    return results

def main():
    # Since this script runs in the 'dextrous' sub-directory, paths should be relative
    # We will look for files in the same directory as this script.
    script_dir = os.path.dirname(os.path.abspath(__file__))
    parent_dir = os.path.dirname(script_dir)
    
    char_pattern = os.path.join(script_dir, "MonuMentuM Characters *.json")
    spec_pattern = os.path.join(script_dir, "MonuMentuM Specials *.json")
    
    char_json_path = find_latest_file(char_pattern)
    spec_json_path = find_latest_file(spec_pattern)
    
    if not char_json_path:
        print(f"Error: No character JSON found matching pattern: {char_pattern}")
        return
    if not spec_json_path:
        print(f"Error: No specials JSON found matching pattern: {spec_pattern}")
        return

    print(f"Processing Characters file: {os.path.basename(char_json_path)}")
    print(f"Processing Specials file: {os.path.basename(spec_json_path)}")

    # Load corresponding CSV files from parent directory
    char_csv_path = os.path.join(parent_dir, "M3_TTS_DB - IN Cha-Tal.csv")
    spec_csv_path = os.path.join(parent_dir, "M3_TTS_DB - IN SP.csv")
    
    char_csv_rows = load_csv_rows(char_csv_path)
    spec_csv_rows = load_csv_rows(spec_csv_path)

    # Process Characters
    with open(char_json_path, "r", encoding="utf-8") as f:
        char_data = json.load(f)
    
    char_deck = char_data["ObjectStates"][0]
    char_deck_ids = char_deck["DeckIDs"]
    char_custom_deck = char_deck["CustomDeck"]
    char_contained = char_deck.get("ContainedObjects", [])
    
    # Inject metadata (Nickname & GMNotes) into Character card states
    print(f"Injecting metadata for {len(char_contained)} characters...")
    for i, card_obj in enumerate(char_contained):
        if i < len(char_csv_rows):
            name_val = char_csv_rows[i].get("Name (str)", "").strip()
            id_val = char_csv_rows[i].get("ID (str)", "").strip()
            # Task 2 Support: If ID is blank (e.g. Loyal Companions/Talismans), generate a deterministic synthetic ID
            if not id_val and name_val:
                id_val = "SYN-" + "".join(c for c in name_val if c.isalnum()).upper()
            card_obj["Nickname"] = name_val
            card_obj["GMNotes"] = id_val

    # Write updated Character JSON back
    with open(char_json_path, "w", encoding="utf-8") as f:
        json.dump(char_data, f, indent=2)
    print(f"Updated {os.path.basename(char_json_path)} with Nicknames and GMNotes.")
    
    char_mappings = []
    for card_id in char_deck_ids:
        deck_num = card_id // 100
        card_idx = card_id % 100
        deck_info = char_custom_deck[str(deck_num)]
        
        char_mappings.append({
            "url": clean_url(deck_info.get("FaceUrl")),
            "cols": deck_info.get("NumWidth", 8),
            "rows": deck_info.get("NumHeight", 6),
            "idx": card_idx
        })

    # Process Specials
    with open(spec_json_path, "r", encoding="utf-8") as f:
        spec_data = json.load(f)
        
    spec_deck = spec_data["ObjectStates"][0]
    spec_deck_ids = spec_deck["DeckIDs"]
    spec_custom_deck = spec_deck["CustomDeck"]
    spec_contained = spec_deck.get("ContainedObjects", [])
    
    # Inject metadata (Nickname & GMNotes) into Specials card states
    print(f"Injecting metadata for {len(spec_contained)} specials...")
    for i, card_obj in enumerate(spec_contained):
        if i < len(spec_csv_rows):
            name_val = spec_csv_rows[i].get("Name (str)", "").strip()
            id_val = spec_csv_rows[i].get("ID (str)", "").strip()
            # Task 2 Support: If ID is blank, generate a deterministic synthetic ID
            if not id_val and name_val:
                id_val = "SYN-" + "".join(c for c in name_val if c.isalnum()).upper()
            card_obj["Nickname"] = name_val
            card_obj["GMNotes"] = id_val

    # Write updated Specials JSON back
    with open(spec_json_path, "w", encoding="utf-8") as f:
        json.dump(spec_data, f, indent=2)
    print(f"Updated {os.path.basename(spec_json_path)} with Nicknames and GMNotes.")
    
    spec_mappings = []
    for card_id in spec_deck_ids:
        deck_num = card_id // 100
        card_idx = card_id % 100
        deck_info = spec_custom_deck[str(deck_num)]
        
        spec_mappings.append({
            "url": clean_url(deck_info.get("FaceUrl")),
            "cols": deck_info.get("NumWidth", 8),
            "rows": deck_info.get("NumHeight", 6),
            "idx": card_idx
        })

    # Write CardImages.gs inside the parent directory (project root)
    output_path = os.path.join(parent_dir, "CardImages.gs")
    
    gs_content = f"""/**
 * Auto-generated card image mappings from Tabletop Simulator Saved Objects.
 * Generated on: Friday, 5 June 2026
 * DO NOT EDIT THIS FILE MANUALLY.
 */

function getCardImageMappings() {{
  return {{
    characters: {json.dumps(char_mappings, indent=2)},
    specials: {json.dumps(spec_mappings, indent=2)}
  }};
}}
"""
    
    with open(output_path, "w", encoding="utf-8") as f:
        f.write(gs_content)
        
    print(f"Successfully generated {output_path} with {len(char_mappings)} characters and {len(spec_mappings)} specials.")

if __name__ == "__main__":
    main()
