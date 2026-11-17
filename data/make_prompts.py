"""Build the fixed 100-prompt workload set (data/prompts.jsonl).

Mix from the proposal: short QA, reasoning, few-shot. The models are *base* models,
so every prompt is written as a completion ("Q: ... A:") rather than a chat turn.
Deterministic: running it twice gives the same file.

    python3 data/make_prompts.py
"""
import json
import random
from pathlib import Path

random.seed(1234)

QA = [
    ("What is the capital of France?", "Paris"),
    ("What is the largest planet in the solar system?", "Jupiter"),
    ("Who wrote Romeo and Juliet?", "William Shakespeare"),
    ("What is the chemical symbol for gold?", "Au"),
    ("How many continents are there on Earth?", "7"),
    ("What gas do plants absorb from the air for photosynthesis?", "carbon dioxide"),
    ("What is the boiling point of water at sea level in degrees Celsius?", "100"),
    ("Which ocean is the largest?", "Pacific"),
    ("What is the square root of 81?", "9"),
    ("Who painted the Mona Lisa?", "Leonardo da Vinci"),
    ("What is the capital of Japan?", "Tokyo"),
    ("What is the hardest natural substance?", "diamond"),
    ("How many legs does a spider have?", "8"),
    ("What is the freezing point of water in degrees Fahrenheit?", "32"),
    ("Which planet is known as the Red Planet?", "Mars"),
    ("What is the longest river in Africa?", "Nile"),
    ("What language is primarily spoken in Brazil?", "Portuguese"),
    ("What is the smallest prime number?", "2"),
    ("Who developed the theory of general relativity?", "Albert Einstein"),
    ("What is the capital of Australia?", "Canberra"),
    ("What organ pumps blood through the human body?", "heart"),
    ("How many days are in a leap year?", "366"),
    ("What is H2O commonly called?", "water"),
    ("What is the capital of Canada?", "Ottawa"),
    ("What is the main language used to style web pages?", "CSS"),
    ("How many bits are in a byte?", "8"),
    ("What is the currency of the United Kingdom?", "pound sterling"),
    ("Which element has the atomic number 1?", "hydrogen"),
    ("What is the tallest mountain on Earth?", "Mount Everest"),
    ("Who was the first person to walk on the Moon?", "Neil Armstrong"),
    ("What is the capital of Italy?", "Rome"),
    ("What is the largest mammal?", "blue whale"),
    ("In computing, what does CPU stand for?", "central processing unit"),
    ("What is the capital of Germany?", "Berlin"),
]


def reasoning_items(n):
    """Short arithmetic word problems with a known numeric answer."""
    names = ["Ana", "Ben", "Chen", "Dara", "Eli", "Fatima", "Goran", "Hana", "Ivan", "Joy"]
    things = ["apples", "pencils", "books", "marbles", "stickers", "coins", "cards", "shells"]
    out = []
    for i in range(n):
        name, thing = random.choice(names), random.choice(things)
        a, b, c = random.randint(5, 40), random.randint(2, 15), random.randint(2, 6)
        kind = i % 3
        if kind == 0:
            q = (f"{name} has {a} {thing}. {name} buys {b} more and then gives away {c}. "
                 f"How many {thing} does {name} have now?")
            ans = a + b - c
        elif kind == 1:
            q = (f"A box holds {c} rows of {b} {thing}. {name} has {a % 5 + 2} full boxes. "
                 f"How many {thing} is that in total?")
            ans = c * b * (a % 5 + 2)
        else:
            total = b * c
            q = (f"{name} shares {total} {thing} equally among {c} friends. "
                 f"How many {thing} does each friend get?")
            ans = b
        out.append((q, str(ans)))
    return out


FEWSHOT_TASKS = {
    "antonym": [("hot", "cold"), ("up", "down"), ("fast", "slow"), ("happy", "sad"),
                ("light", "dark"), ("open", "closed"), ("early", "late"), ("full", "empty"),
                ("strong", "weak"), ("young", "old"), ("rich", "poor"), ("wet", "dry")],
    "country_capital": [("Spain", "Madrid"), ("Egypt", "Cairo"), ("Kenya", "Nairobi"),
                        ("Peru", "Lima"), ("Norway", "Oslo"), ("Greece", "Athens"),
                        ("Vietnam", "Hanoi"), ("Chile", "Santiago"), ("Poland", "Warsaw"),
                        ("Thailand", "Bangkok"), ("Ireland", "Dublin"), ("Cuba", "Havana")],
    "sentiment": [("I loved this movie, it was wonderful.", "positive"),
                  ("The food was cold and tasteless.", "negative"),
                  ("Best purchase I have made all year.", "positive"),
                  ("The service was slow and rude.", "negative"),
                  ("What a fantastic concert!", "positive"),
                  ("I want my money back.", "negative"),
                  ("The hotel room was clean and cozy.", "positive"),
                  ("This phone breaks every week.", "negative"),
                  ("An absolute joy to read.", "positive"),
                  ("Terrible, would not recommend.", "negative")],
}


def fewshot_items(n, shots=4):
    out = []
    tasks = list(FEWSHOT_TASKS)
    for i in range(n):
        task = tasks[i % len(tasks)]
        pairs = FEWSHOT_TASKS[task][:]
        random.shuffle(pairs)
        demos, (x, y) = pairs[:shots], pairs[shots]
        if task == "sentiment":
            body = "".join(f"Review: {a}\nSentiment: {b}\n\n" for a, b in demos)
            prompt = body + f"Review: {x}\nSentiment:"
        else:
            label = {"antonym": ("Word", "Antonym"), "country_capital": ("Country", "Capital")}[task]
            body = "".join(f"{label[0]}: {a}\n{label[1]}: {b}\n\n" for a, b in demos)
            prompt = body + f"{label[0]}: {x}\n{label[1]}:"
        out.append({"category": "fewshot", "task": task, "prompt": prompt, "answer": y})
    return out


def main():
    rows = [{"category": "qa", "prompt": f"Q: {q}\nA:", "answer": a} for q, a in QA]
    rows += [{"category": "reasoning",
              "prompt": f"Q: {q}\nA: Let's think step by step.", "answer": a}
             for q, a in reasoning_items(33)]
    rows += fewshot_items(33)
    assert len(rows) == 100, len(rows)
    for i, r in enumerate(rows):
        r["id"] = i
    out = Path(__file__).with_name("prompts.jsonl")
    out.write_text("".join(json.dumps(r) + "\n" for r in rows))
    print(f"wrote {len(rows)} prompts to {out}")


if __name__ == "__main__":
    main()
