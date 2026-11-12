# The 100 test prompts

Source: `data/prompts.jsonl` (built by `data/make_prompts.py`). Each prompt is sent as-is; the model's answer counts as correct if the expected answer appears in it.

## Short QA (34 prompts)

**1.** Q: What is the capital of France? A:  
Expected: **Paris**

**2.** Q: What is the largest planet in the solar system? A:  
Expected: **Jupiter**

**3.** Q: Who wrote Romeo and Juliet? A:  
Expected: **William Shakespeare**

**4.** Q: What is the chemical symbol for gold? A:  
Expected: **Au**

**5.** Q: How many continents are there on Earth? A:  
Expected: **7**

**6.** Q: What gas do plants absorb from the air for photosynthesis? A:  
Expected: **carbon dioxide**

**7.** Q: What is the boiling point of water at sea level in degrees Celsius? A:  
Expected: **100**

**8.** Q: Which ocean is the largest? A:  
Expected: **Pacific**

**9.** Q: What is the square root of 81? A:  
Expected: **9**

**10.** Q: Who painted the Mona Lisa? A:  
Expected: **Leonardo da Vinci**

**11.** Q: What is the capital of Japan? A:  
Expected: **Tokyo**

**12.** Q: What is the hardest natural substance? A:  
Expected: **diamond**

**13.** Q: How many legs does a spider have? A:  
Expected: **8**

**14.** Q: What is the freezing point of water in degrees Fahrenheit? A:  
Expected: **32**

**15.** Q: Which planet is known as the Red Planet? A:  
Expected: **Mars**

**16.** Q: What is the longest river in Africa? A:  
Expected: **Nile**

**17.** Q: What language is primarily spoken in Brazil? A:  
Expected: **Portuguese**

**18.** Q: What is the smallest prime number? A:  
Expected: **2**

**19.** Q: Who developed the theory of general relativity? A:  
Expected: **Albert Einstein**

**20.** Q: What is the capital of Australia? A:  
Expected: **Canberra**

**21.** Q: What organ pumps blood through the human body? A:  
Expected: **heart**

**22.** Q: How many days are in a leap year? A:  
Expected: **366**

**23.** Q: What is H2O commonly called? A:  
Expected: **water**

**24.** Q: What is the capital of Canada? A:  
Expected: **Ottawa**

**25.** Q: What is the main language used to style web pages? A:  
Expected: **CSS**

**26.** Q: How many bits are in a byte? A:  
Expected: **8**

**27.** Q: What is the currency of the United Kingdom? A:  
Expected: **pound sterling**

**28.** Q: Which element has the atomic number 1? A:  
Expected: **hydrogen**

**29.** Q: What is the tallest mountain on Earth? A:  
Expected: **Mount Everest**

**30.** Q: Who was the first person to walk on the Moon? A:  
Expected: **Neil Armstrong**

**31.** Q: What is the capital of Italy? A:  
Expected: **Rome**

**32.** Q: What is the largest mammal? A:  
Expected: **blue whale**

**33.** Q: In computing, what does CPU stand for? A:  
Expected: **central processing unit**

**34.** Q: What is the capital of Germany? A:  
Expected: **Berlin**

## Reasoning (arithmetic word problems) (33 prompts)

**35.** Q: Hana has 5 pencils. Hana buys 3 more and then gives away 6. How many pencils does Hana have now? A: Let's think step by step.  
Expected: **2**

**36.** Q: A box holds 4 rows of 14 pencils. Ana has 3 full boxes. How many pencils is that in total? A: Let's think step by step.  
Expected: **168**

**37.** Q: Dara shares 28 apples equally among 2 friends. How many apples does each friend get? A: Let's think step by step.  
Expected: **14**

**38.** Q: Fatima has 34 shells. Fatima buys 4 more and then gives away 2. How many shells does Fatima have now? A: Let's think step by step.  
Expected: **36**

**39.** Q: A box holds 5 rows of 10 pencils. Chen has 2 full boxes. How many pencils is that in total? A: Let's think step by step.  
Expected: **100**

**40.** Q: Dara shares 18 pencils equally among 2 friends. How many pencils does each friend get? A: Let's think step by step.  
Expected: **9**

**41.** Q: Joy has 37 pencils. Joy buys 11 more and then gives away 2. How many pencils does Joy have now? A: Let's think step by step.  
Expected: **46**

**42.** Q: A box holds 4 rows of 9 pencils. Eli has 6 full boxes. How many pencils is that in total? A: Let's think step by step.  
Expected: **216**

**43.** Q: Eli shares 54 marbles equally among 6 friends. How many marbles does each friend get? A: Let's think step by step.  
Expected: **9**

**44.** Q: Ana has 5 pencils. Ana buys 7 more and then gives away 3. How many pencils does Ana have now? A: Let's think step by step.  
Expected: **9**

**45.** Q: A box holds 2 rows of 2 cards. Hana has 2 full boxes. How many cards is that in total? A: Let's think step by step.  
Expected: **8**

**46.** Q: Joy shares 18 shells equally among 6 friends. How many shells does each friend get? A: Let's think step by step.  
Expected: **3**

**47.** Q: Dara has 6 books. Dara buys 7 more and then gives away 2. How many books does Dara have now? A: Let's think step by step.  
Expected: **11**

**48.** Q: A box holds 2 rows of 9 books. Ivan has 6 full boxes. How many books is that in total? A: Let's think step by step.  
Expected: **108**

**49.** Q: Goran shares 16 stickers equally among 4 friends. How many stickers does each friend get? A: Let's think step by step.  
Expected: **4**

**50.** Q: Chen has 14 stickers. Chen buys 14 more and then gives away 5. How many stickers does Chen have now? A: Let's think step by step.  
Expected: **23**

**51.** Q: A box holds 4 rows of 9 cards. Ana has 4 full boxes. How many cards is that in total? A: Let's think step by step.  
Expected: **144**

**52.** Q: Joy shares 10 shells equally among 5 friends. How many shells does each friend get? A: Let's think step by step.  
Expected: **2**

**53.** Q: Joy has 33 books. Joy buys 13 more and then gives away 6. How many books does Joy have now? A: Let's think step by step.  
Expected: **40**

**54.** Q: A box holds 3 rows of 3 stickers. Hana has 4 full boxes. How many stickers is that in total? A: Let's think step by step.  
Expected: **36**

**55.** Q: Goran shares 20 cards equally among 2 friends. How many cards does each friend get? A: Let's think step by step.  
Expected: **10**

**56.** Q: Hana has 21 cards. Hana buys 12 more and then gives away 3. How many cards does Hana have now? A: Let's think step by step.  
Expected: **30**

**57.** Q: A box holds 4 rows of 11 pencils. Fatima has 2 full boxes. How many pencils is that in total? A: Let's think step by step.  
Expected: **88**

**58.** Q: Chen shares 26 coins equally among 2 friends. How many coins does each friend get? A: Let's think step by step.  
Expected: **13**

**59.** Q: Ben has 18 cards. Ben buys 2 more and then gives away 4. How many cards does Ben have now? A: Let's think step by step.  
Expected: **16**

**60.** Q: A box holds 2 rows of 15 marbles. Ana has 4 full boxes. How many marbles is that in total? A: Let's think step by step.  
Expected: **120**

**61.** Q: Fatima shares 18 stickers equally among 6 friends. How many stickers does each friend get? A: Let's think step by step.  
Expected: **3**

**62.** Q: Eli has 32 pencils. Eli buys 5 more and then gives away 2. How many pencils does Eli have now? A: Let's think step by step.  
Expected: **35**

**63.** Q: A box holds 3 rows of 10 marbles. Goran has 6 full boxes. How many marbles is that in total? A: Let's think step by step.  
Expected: **180**

**64.** Q: Fatima shares 65 marbles equally among 5 friends. How many marbles does each friend get? A: Let's think step by step.  
Expected: **13**

**65.** Q: Chen has 24 marbles. Chen buys 2 more and then gives away 4. How many marbles does Chen have now? A: Let's think step by step.  
Expected: **22**

**66.** Q: A box holds 6 rows of 14 books. Ivan has 3 full boxes. How many books is that in total? A: Let's think step by step.  
Expected: **252**

**67.** Q: Hana shares 8 coins equally among 2 friends. How many coins does each friend get? A: Let's think step by step.  
Expected: **4**

## Few-shot (4 examples, then the question) (33 prompts)

**68.** (antonym) expected: **empty**

```
Word: light
Antonym: dark

Word: happy
Antonym: sad

Word: early
Antonym: late

Word: hot
Antonym: cold

Word: full
Antonym:
```

**69.** (country_capital) expected: **Bangkok**

```
Country: Chile
Capital: Santiago

Country: Greece
Capital: Athens

Country: Norway
Capital: Oslo

Country: Cuba
Capital: Havana

Country: Thailand
Capital:
```

**70.** (sentiment) expected: **negative**

```
Review: The hotel room was clean and cozy.
Sentiment: positive

Review: I loved this movie, it was wonderful.
Sentiment: positive

Review: I want my money back.
Sentiment: negative

Review: The food was cold and tasteless.
Sentiment: negative

Review: This phone breaks every week.
Sentiment:
```

**71.** (antonym) expected: **sad**

```
Word: strong
Antonym: weak

Word: up
Antonym: down

Word: open
Antonym: closed

Word: fast
Antonym: slow

Word: happy
Antonym:
```

**72.** (country_capital) expected: **Cairo**

```
Country: Kenya
Capital: Nairobi

Country: Norway
Capital: Oslo

Country: Poland
Capital: Warsaw

Country: Chile
Capital: Santiago

Country: Egypt
Capital:
```

**73.** (sentiment) expected: **positive**

```
Review: An absolute joy to read.
Sentiment: positive

Review: This phone breaks every week.
Sentiment: negative

Review: Terrible, would not recommend.
Sentiment: negative

Review: I want my money back.
Sentiment: negative

Review: Best purchase I have made all year.
Sentiment:
```

**74.** (antonym) expected: **poor**

```
Word: up
Antonym: down

Word: happy
Antonym: sad

Word: hot
Antonym: cold

Word: open
Antonym: closed

Word: rich
Antonym:
```

**75.** (country_capital) expected: **Lima**

```
Country: Kenya
Capital: Nairobi

Country: Egypt
Capital: Cairo

Country: Norway
Capital: Oslo

Country: Cuba
Capital: Havana

Country: Peru
Capital:
```

**76.** (sentiment) expected: **negative**

```
Review: I loved this movie, it was wonderful.
Sentiment: positive

Review: The service was slow and rude.
Sentiment: negative

Review: An absolute joy to read.
Sentiment: positive

Review: The hotel room was clean and cozy.
Sentiment: positive

Review: I want my money back.
Sentiment:
```

**77.** (antonym) expected: **closed**

```
Word: early
Antonym: late

Word: fast
Antonym: slow

Word: strong
Antonym: weak

Word: up
Antonym: down

Word: open
Antonym:
```

**78.** (country_capital) expected: **Nairobi**

```
Country: Cuba
Capital: Havana

Country: Peru
Capital: Lima

Country: Spain
Capital: Madrid

Country: Thailand
Capital: Bangkok

Country: Kenya
Capital:
```

**79.** (sentiment) expected: **negative**

```
Review: This phone breaks every week.
Sentiment: negative

Review: What a fantastic concert!
Sentiment: positive

Review: The service was slow and rude.
Sentiment: negative

Review: Best purchase I have made all year.
Sentiment: positive

Review: Terrible, would not recommend.
Sentiment:
```

**80.** (antonym) expected: **empty**

```
Word: fast
Antonym: slow

Word: hot
Antonym: cold

Word: wet
Antonym: dry

Word: young
Antonym: old

Word: full
Antonym:
```

**81.** (country_capital) expected: **Warsaw**

```
Country: Norway
Capital: Oslo

Country: Cuba
Capital: Havana

Country: Kenya
Capital: Nairobi

Country: Vietnam
Capital: Hanoi

Country: Poland
Capital:
```

**82.** (sentiment) expected: **positive**

```
Review: Terrible, would not recommend.
Sentiment: negative

Review: I loved this movie, it was wonderful.
Sentiment: positive

Review: The hotel room was clean and cozy.
Sentiment: positive

Review: This phone breaks every week.
Sentiment: negative

Review: What a fantastic concert!
Sentiment:
```

**83.** (antonym) expected: **late**

```
Word: light
Antonym: dark

Word: up
Antonym: down

Word: happy
Antonym: sad

Word: open
Antonym: closed

Word: early
Antonym:
```

**84.** (country_capital) expected: **Hanoi**

```
Country: Cuba
Capital: Havana

Country: Chile
Capital: Santiago

Country: Peru
Capital: Lima

Country: Kenya
Capital: Nairobi

Country: Vietnam
Capital:
```

**85.** (sentiment) expected: **positive**

```
Review: What a fantastic concert!
Sentiment: positive

Review: I want my money back.
Sentiment: negative

Review: The food was cold and tasteless.
Sentiment: negative

Review: Best purchase I have made all year.
Sentiment: positive

Review: The hotel room was clean and cozy.
Sentiment:
```

**86.** (antonym) expected: **old**

```
Word: early
Antonym: late

Word: rich
Antonym: poor

Word: strong
Antonym: weak

Word: up
Antonym: down

Word: young
Antonym:
```

**87.** (country_capital) expected: **Santiago**

```
Country: Ireland
Capital: Dublin

Country: Greece
Capital: Athens

Country: Vietnam
Capital: Hanoi

Country: Spain
Capital: Madrid

Country: Chile
Capital:
```

**88.** (sentiment) expected: **positive**

```
Review: This phone breaks every week.
Sentiment: negative

Review: I loved this movie, it was wonderful.
Sentiment: positive

Review: An absolute joy to read.
Sentiment: positive

Review: The food was cold and tasteless.
Sentiment: negative

Review: Best purchase I have made all year.
Sentiment:
```

**89.** (antonym) expected: **poor**

```
Word: wet
Antonym: dry

Word: full
Antonym: empty

Word: happy
Antonym: sad

Word: fast
Antonym: slow

Word: rich
Antonym:
```

**90.** (country_capital) expected: **Madrid**

```
Country: Thailand
Capital: Bangkok

Country: Chile
Capital: Santiago

Country: Poland
Capital: Warsaw

Country: Vietnam
Capital: Hanoi

Country: Spain
Capital:
```

**91.** (sentiment) expected: **positive**

```
Review: I loved this movie, it was wonderful.
Sentiment: positive

Review: The food was cold and tasteless.
Sentiment: negative

Review: The hotel room was clean and cozy.
Sentiment: positive

Review: The service was slow and rude.
Sentiment: negative

Review: An absolute joy to read.
Sentiment:
```

**92.** (antonym) expected: **slow**

```
Word: happy
Antonym: sad

Word: up
Antonym: down

Word: light
Antonym: dark

Word: hot
Antonym: cold

Word: fast
Antonym:
```

**93.** (country_capital) expected: **Athens**

```
Country: Ireland
Capital: Dublin

Country: Vietnam
Capital: Hanoi

Country: Peru
Capital: Lima

Country: Cuba
Capital: Havana

Country: Greece
Capital:
```

**94.** (sentiment) expected: **positive**

```
Review: The service was slow and rude.
Sentiment: negative

Review: I loved this movie, it was wonderful.
Sentiment: positive

Review: Terrible, would not recommend.
Sentiment: negative

Review: This phone breaks every week.
Sentiment: negative

Review: What a fantastic concert!
Sentiment:
```

**95.** (antonym) expected: **late**

```
Word: up
Antonym: down

Word: fast
Antonym: slow

Word: strong
Antonym: weak

Word: happy
Antonym: sad

Word: early
Antonym:
```

**96.** (country_capital) expected: **Cairo**

```
Country: Norway
Capital: Oslo

Country: Vietnam
Capital: Hanoi

Country: Spain
Capital: Madrid

Country: Poland
Capital: Warsaw

Country: Egypt
Capital:
```

**97.** (sentiment) expected: **positive**

```
Review: The hotel room was clean and cozy.
Sentiment: positive

Review: What a fantastic concert!
Sentiment: positive

Review: An absolute joy to read.
Sentiment: positive

Review: The service was slow and rude.
Sentiment: negative

Review: Best purchase I have made all year.
Sentiment:
```

**98.** (antonym) expected: **weak**

```
Word: open
Antonym: closed

Word: up
Antonym: down

Word: full
Antonym: empty

Word: wet
Antonym: dry

Word: strong
Antonym:
```

**99.** (country_capital) expected: **Athens**

```
Country: Spain
Capital: Madrid

Country: Egypt
Capital: Cairo

Country: Vietnam
Capital: Hanoi

Country: Cuba
Capital: Havana

Country: Greece
Capital:
```

**100.** (sentiment) expected: **negative**

```
Review: An absolute joy to read.
Sentiment: positive

Review: The food was cold and tasteless.
Sentiment: negative

Review: I loved this movie, it was wonderful.
Sentiment: positive

Review: Best purchase I have made all year.
Sentiment: positive

Review: The service was slow and rude.
Sentiment:
```
