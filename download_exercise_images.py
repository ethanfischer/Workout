#!/usr/bin/env python3
"""
Download exercise images from free-exercise-db for exercises missing videos.
"""

import requests
import os
import json
from difflib import SequenceMatcher

# Exercises that we DON'T have videos for
MISSING_EXERCISES = [
    "Push Ups",
    "Lateral Raises",
    "Front Raises",
    "DB Chest Flys",
    "Tricep Rope Pushdown",
    "Rear Delt Fly",
    "Lat Pulldown",
    "Seated Row",
    "DB Pullovers",
    "Stiff Arm Pulldown",
    "Rope Face Pull",
    "DB Curls",
    "Hip Thrust",
    "Lunges",
    "Split Squats",
    "Split Stance RDL",
    "Step Ups",
    "Split Stance Hip Thrust",
    "Cable Kickbacks",
    "Abductions",
]

# Map exercise names to better search terms
SEARCH_ALIASES = {
    "Push Ups": ["Push-Up", "Pushup", "Push Up"],
    "Lateral Raises": ["Lateral Raise", "Side Lateral Raise", "Dumbbell Lateral Raise"],
    "Front Raises": ["Front Raise", "Front Dumbbell Raise"],
    "DB Chest Flys": ["Dumbbell Fly", "Dumbbell Flye", "Chest Fly"],
    "Tricep Rope Pushdown": ["Triceps Pushdown", "Cable Pushdown", "Rope Pushdown"],
    "Rear Delt Fly": ["Rear Delt Raise", "Reverse Fly", "Bent Over Lateral Raise"],
    "Lat Pulldown": ["Lat Pulldown", "Wide-Grip Lat Pulldown"],
    "Seated Row": ["Seated Cable Row", "Cable Row", "Seated Row"],
    "DB Pullovers": ["Pullover", "Dumbbell Pullover"],
    "Stiff Arm Pulldown": ["Straight-Arm Pulldown", "Stiff Arm Pulldown"],
    "Rope Face Pull": ["Face Pull", "Cable Face Pull"],
    "DB Curls": ["Dumbbell Curl", "Bicep Curl", "Dumbbell Bicep Curl"],
    "Hip Thrust": ["Hip Thrust", "Barbell Hip Thrust", "Glute Bridge"],
    "Lunges": ["Lunge", "Dumbbell Lunge", "Walking Lunge"],
    "Split Squats": ["Split Squat", "Bulgarian Split Squat"],
    "Split Stance RDL": ["Single Leg Deadlift", "Romanian Deadlift"],
    "Step Ups": ["Step Up", "Dumbbell Step Up", "Barbell Step Up"],
    "Split Stance Hip Thrust": ["Single Leg Hip Thrust", "Hip Thrust"],
    "Cable Kickbacks": ["Cable Kickback", "Glute Kickback"],
    "Abductions": ["Hip Abduction", "Cable Hip Abduction", "Side Lying Hip Abduction"],
}

OUTPUT_DIR = "exercise_images"
BASE_URL = "https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises"


def similarity(a: str, b: str) -> float:
    """Calculate string similarity."""
    return SequenceMatcher(None, a.lower(), b.lower()).ratio()


def find_best_match(exercise_name: str, all_exercises: list) -> dict | None:
    """Find the best matching exercise from the database."""
    aliases = SEARCH_ALIASES.get(exercise_name, [exercise_name])

    best_match = None
    best_score = 0

    for ex in all_exercises:
        db_name = ex["name"]
        for alias in aliases:
            score = similarity(alias, db_name)
            if score > best_score:
                best_score = score
                best_match = ex

    if best_score >= 0.5:
        return best_match
    return None


def download_image(image_path: str, output_path: str) -> bool:
    """Download an image file."""
    url = f"{BASE_URL}/{image_path}"

    try:
        resp = requests.get(url, timeout=10)
        resp.raise_for_status()

        with open(output_path, "wb") as f:
            f.write(resp.content)
        return True
    except Exception as e:
        print(f"  Error downloading {url}: {e}")
        return False


def sanitize_filename(name: str) -> str:
    """Convert exercise name to valid filename."""
    return name.lower().replace(" ", "_").replace("/", "_")


def main():
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    # Fetch the exercise database
    print("Fetching exercise database...")
    resp = requests.get("https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/dist/exercises.json")
    all_exercises = resp.json()
    print(f"Loaded {len(all_exercises)} exercises\n")

    results = {"found": [], "not_found": [], "downloaded": []}

    for exercise in MISSING_EXERCISES:
        print(f"🔍 {exercise}...")

        match = find_best_match(exercise, all_exercises)

        if not match:
            print(f"  ❌ No match found")
            results["not_found"].append(exercise)
            continue

        print(f"  ✓ Matched: {match['name']}")
        results["found"].append((exercise, match["name"]))

        # Get images
        images = match.get("images", [])
        if not images:
            print(f"  ⚠️  No images available")
            continue

        # Download first image
        image_path = images[0]
        ext = os.path.splitext(image_path)[1] or ".jpg"
        filename = f"{sanitize_filename(exercise)}{ext}"
        output_path = os.path.join(OUTPUT_DIR, filename)

        if os.path.exists(output_path):
            print(f"  ⏭️  Already downloaded")
            results["downloaded"].append(exercise)
            continue

        # The image path in the JSON is like "Clock_Push-Up/0.jpg"
        # which already includes the exercise id folder
        full_image_path = images[0]

        print(f"  ⬇️  Downloading {full_image_path}...")
        if download_image(full_image_path, output_path):
            print(f"  ✅ Saved to {filename}")
            results["downloaded"].append(exercise)

    # Summary
    print("\n" + "=" * 50)
    print("SUMMARY")
    print("=" * 50)
    print(f"✅ Downloaded: {len(results['downloaded'])}")
    print(f"❌ Not found:  {len(results['not_found'])}")

    if results["not_found"]:
        print(f"\nNot found: {', '.join(results['not_found'])}")


if __name__ == "__main__":
    main()
