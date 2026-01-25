#!/usr/bin/env python3
"""
Download GIFs for new exercise list - dumbbells, resistance bands, bench only.
"""

import requests
import os
import time
from urllib.parse import quote

API_KEY = "8e74913321msh2681d810ff73ad7p141968jsn44537037ca5f"
HEADERS = {
    "x-rapidapi-host": "exercisedb.p.rapidapi.com",
    "x-rapidapi-key": API_KEY,
}

# (filename, search_term) - prioritizing dumbbell/band versions
EXERCISES = [
    # PUSH
    ("push_ups", "push up"),
    ("db_overhead_press", "dumbbell shoulder press"),
    ("db_bench_press", "dumbbell bench press"),
    ("db_lateral_raises", "dumbbell lateral raise"),
    ("db_front_raises", "dumbbell front raise"),
    ("tricep_rope_pushdown", "cable pushdown"),
    ("db_skullcrushers", "dumbbell lying triceps extension"),
    ("db_chest_flys", "dumbbell fly"),

    # PULL
    ("banded_lat_pulldown", "lat pulldown"),
    ("chest_supported_db_row", "dumbbell incline row"),
    ("bent_over_row", "dumbbell bent over row"),
    ("db_upright_row", "dumbbell upright row"),
    ("db_pullovers", "dumbbell pullover"),
    ("renegade_rows", "renegade row"),
    ("banded_face_pull", "face pull"),
    ("db_curls", "bicep curl"),

    # LEGS
    ("goblet_squat", "dumbbell goblet squat"),
    ("sumo_squat", "sumo squat"),
    ("db_front_squat", "dumbbell squat"),
    ("db_deadlift", "dumbbell deadlift"),
    ("banded_hip_thrust", "hip thrust"),
    ("db_lunges", "dumbbell lunge"),
    ("db_split_squats", "split squat"),
    ("db_split_stance_rdl", "dumbbell single leg deadlift"),
    ("db_step_ups", "dumbbell step up"),
    ("db_split_stance_hip_thrust", "single leg hip thrust"),
    ("sissy_squat", "sissy squat"),
    ("resistance_band_hamstring_curl", "leg curl"),
    ("banded_kickbacks", "kickback"),
    ("banded_lateral_walks", "lateral walk"),
    ("side_lying_banded_leg_raise", "side lying leg raise"),
    ("db_calf_raises", "calf raise"),
]

OUTPUT_DIR = "new_exercise_gifs"

# Equipment we want to prioritize (no barbells/machines)
PREFERRED_EQUIPMENT = ["dumbbell", "body weight", "resistance band", "band", "cable", "stability ball"]
EXCLUDE_EQUIPMENT = ["barbell", "ez barbell", "olympic barbell", "smith machine", "sled machine", "leverage machine"]


def search_exercise(search_term: str) -> list:
    """Search for exercises and return results."""
    url = f"https://exercisedb.p.rapidapi.com/exercises/name/{quote(search_term)}?limit=10"
    try:
        resp = requests.get(url, headers=HEADERS, timeout=15)
        resp.raise_for_status()
        return resp.json()
    except Exception as e:
        print(f"  Search error: {e}")
        return []


def download_gif(exercise_id: str, output_path: str) -> bool:
    """Download GIF using the exercise ID via API endpoint."""
    url = f"https://exercisedb.p.rapidapi.com/image?exerciseId={exercise_id}&resolution=360"
    try:
        resp = requests.get(url, headers=HEADERS, timeout=30)
        resp.raise_for_status()
        if resp.headers.get('content-type', '').startswith('image'):
            with open(output_path, 'wb') as f:
                f.write(resp.content)
            return True
        print(f"  Unexpected content type: {resp.headers.get('content-type')}")
        return False
    except Exception as e:
        print(f"  Download error: {e}")
        return False


def pick_best_exercise(results: list) -> dict | None:
    """Pick the best exercise from results, preferring dumbbell/bodyweight."""
    if not results:
        return None

    # First pass: look for preferred equipment
    for r in results:
        equip = r.get("equipment", "").lower()
        if any(pref in equip for pref in PREFERRED_EQUIPMENT):
            if not any(excl in equip for excl in EXCLUDE_EQUIPMENT):
                return r

    # Second pass: anything not excluded
    for r in results:
        equip = r.get("equipment", "").lower()
        if not any(excl in equip for excl in EXCLUDE_EQUIPMENT):
            return r

    # Fallback: first result
    return results[0]


def main():
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    print(f"\nDownloading GIFs for {len(EXERCISES)} exercises...\n")

    downloaded = []
    failed = []

    for filename, search_term in EXERCISES:
        output_path = os.path.join(OUTPUT_DIR, f"{filename}.gif")
        print(f"🔍 {filename}...")

        if os.path.exists(output_path):
            size_kb = os.path.getsize(output_path) / 1024
            print(f"  ⏭️  Already exists ({size_kb:.0f} KB)")
            downloaded.append(filename)
            continue

        results = search_exercise(search_term)
        data = pick_best_exercise(results)

        if not data:
            print(f"  ❌ Not found for '{search_term}'")
            failed.append((filename, search_term))
            time.sleep(0.5)
            continue

        exercise_id = data.get("id")
        exercise_name = data.get("name")
        equipment = data.get("equipment")

        print(f"  ✓ Found: {exercise_name} ({equipment}) [ID: {exercise_id}]")

        if download_gif(exercise_id, output_path):
            size_kb = os.path.getsize(output_path) / 1024
            print(f"  ✅ Saved ({size_kb:.0f} KB)")
            downloaded.append(filename)
        else:
            failed.append((filename, search_term))

        time.sleep(1)  # Rate limit

    # Summary
    print("\n" + "=" * 50)
    print(f"✅ Downloaded: {len(downloaded)}/{len(EXERCISES)}")
    if failed:
        print(f"❌ Failed: {len(failed)}")
        for name, term in failed:
            print(f"   - {name} (searched: '{term}')")

    print(f"\nGIFs saved to: {OUTPUT_DIR}/")

    if downloaded:
        total = sum(os.path.getsize(os.path.join(OUTPUT_DIR, f"{f}.gif"))
                    for f in downloaded if os.path.exists(os.path.join(OUTPUT_DIR, f"{f}.gif")))
        print(f"Total size: {total / 1024 / 1024:.1f} MB")


if __name__ == "__main__":
    main()
