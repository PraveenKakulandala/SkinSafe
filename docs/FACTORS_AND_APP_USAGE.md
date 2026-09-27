# Factors Considered When Communicating a Possible Cancer Warning and How They Can Be Applied in the App

**Prepared for supervisor discussion**  
**Project:** SkinSafe  
**Date:** August 13, 2026

---

## 1. Introduction

When a doctor communicates a serious warning such as a possible cancer-related finding, the message is not delivered based only on the medical result. Doctors also consider the emotional, social, practical, and psychological condition of the patient. These same ideas can be applied to the design of a mobile health application such as SkinSafe.

This document explains the main factors involved in doctor-patient communication and shows how each factor can be translated into practical app design decisions.

---

## 2. Mental State of the Patient

### Why it matters

If a patient is already anxious, frightened, or emotionally overwhelmed, harsh or direct wording can increase panic. For this reason, doctors usually communicate carefully, observe the patient’s reaction, and explain serious findings gradually.

### How it can be used in the app

The app should avoid shocking or panic-inducing language. Instead of using phrases such as:

- Cancer detected
- Dangerous result
- Immediate threat

the app should use supportive and action-focused wording such as:

- Caution advised
- Specialist review recommended
- This finding deserves closer review

### Practical app design tricks

- Use calm and supportive headings on the result screen
- Avoid flashing red warning visuals or aggressive alert language
- Present the result in stages:
  - short result summary
  - simple explanation
  - next action
- Use soft colors and medically calm visual design
- Add supportive lines such as:
  - “This result is intended to guide your next step.”
  - “Please review this calmly and consider professional advice if needed.”

---

## 3. Economic and Socioeconomic Factors

### Why it matters

Even if a doctor gives the correct warning, a patient may not be able to immediately afford specialist consultation, laboratory tests, transport, or time away from work. Therefore, doctors often think practically as well as clinically.

### How it can be used in the app

The app should not only give a warning. It should also suggest realistic and practical next steps that are manageable for different users.

### Practical app design tricks

- Offer a “save and monitor” path for follow-up
- Allow users to repeat scans later and compare history
- Use guidance such as:
  - “Repeat this scan in a few days if the lesion changes.”
  - “Seek dermatologist review if this pattern continues.”
- Avoid forcing only one costly or urgent path unless the risk message truly requires it
- Help users organize information before seeing a doctor by saving history and comparisons

---

## 4. Health Literacy

### Why it matters

Many patients may not understand technical medical words such as melanoma, malignant, lesion, or biopsy. Doctors often simplify language depending on the patient’s educational and medical understanding.

### How it can be used in the app

The app should explain results using simple, plain language. Technical words should be minimized or explained clearly.

### Practical app design tricks

- Replace technical wording with patient-friendly phrasing
- Add “What this means” sections on the result screen
- Use short explanations under medical terms
- Teach the ABCDE rule using very simple cards and examples
- Use layered information:
  - simple summary first
  - more technical explanation only if the user wants more details

Examples:

- Instead of “malignant risk,” use “higher concern pattern”
- Instead of “biopsy may be indicated,” use “a doctor may recommend a small medical test for closer examination”

---

## 5. Family Support and Social Context

### Why it matters

Some patients cope better when a family member or trusted supporter is involved. Others may prefer private review first. Doctors often adapt communication based on the patient’s support system and personal preference.

### How it can be used in the app

The app can allow the user to save, review, and later share the result. This supports discussion with a family member or doctor without forcing immediate emotional decisions.

### Practical app design tricks

- Allow users to save the result in history
- Provide a summary that can be shown later during consultation
- Add language such as:
  - “You may wish to discuss this result with a family member or clinician.”
- Support future share/report features
- Avoid forcing a user to react instantly on the same screen

---

## 6. Privacy, Setting, and Timing

### Why it matters

Doctors do not normally give serious news in an exposed, noisy, or rushed environment. Privacy and timing influence how safely the patient receives the information.

### How it can be used in the app

The result screen should feel calm, private, and focused. Sensitive results should not be displayed in a visually chaotic or alarm-heavy way.

### Practical app design tricks

- Use a clean, uncluttered result layout
- Reduce unnecessary distractions on the result page
- Keep the tone quiet and respectful
- Use progressive disclosure rather than dumping too much information at once
- Present next steps clearly and calmly

---

## 7. Patient Preference and Readiness

### Why it matters

Not every patient wants the same amount of information immediately. Some prefer a short summary first. Others want detailed explanation and probabilities.

### How it can be used in the app

The app should let users move from basic to detailed information gradually.

### Practical app design tricks

- Show a simple summary first
- Add optional detailed explanation below
- Use sections such as:
  - Result summary
  - What this means
  - What to do next
- Keep high-level advice visible even if technical details are hidden

---

## 8. The SPIKES Protocol and Its Application in the App

The SPIKES protocol is a widely used framework for breaking bad news in a structured and empathetic way.

SPIKES stands for:

- **S** – Setting
- **P** – Perception
- **I** – Invitation
- **K** – Knowledge
- **E** – Empathy
- **S** – Strategy and Summary

### How SPIKES can be translated into the app

#### Setting

The app should use a calm screen layout and present sensitive results in a private-feeling, respectful interface.

#### Perception

The questionnaire before the scan can help capture what the user has already noticed, such as visible changes or concern history.

#### Invitation

The app can first show a short summary and then allow the user to choose whether to read more detailed information.

#### Knowledge

The app can present the risk result in simple language with clear explanation.

#### Empathy

The app can use soft wording and avoid panic-based phrasing.

#### Strategy and Summary

The app can conclude with practical next steps such as:

- save to history
- repeat scan later
- compare previous lesion images
- seek specialist review when needed

### Why this is useful

Using the SPIKES idea helps transform the app from a simple image-classification tool into a more ethical and patient-centered digital health system.

---

## 9. Summary of How the Factors Translate into App Features

| Factor | Why Doctors Consider It | Example App Response |
|---|---|---|
| Mental state | To avoid panic and emotional overload | Calm wording, soft UI, supportive result summary |
| Economic factors | To make next steps realistic and practical | Save history, follow-up guidance, repeat scan options |
| Health literacy | To ensure understanding | Plain language, simplified medical explanation |
| Family/support | To improve coping and follow-up | Save/share-ready result summary, history review |
| Privacy/setting | To protect dignity and reduce stress | Clean result screen, no alarming interface |
| Readiness/preference | To match user information needs | Short summary first, detail sections later |
| SPIKES structure | To communicate difficult findings ethically | Guided result flow with empathy and action plan |

---

## 10. Conclusion

The factors doctors consider when communicating a possible cancer warning can be directly applied to a mobile application. In SkinSafe, these factors are not only medical communication ideas; they become practical design principles.

By considering mental state, economic limitations, health literacy, family support, privacy, and SPIKES-based communication structure, the application can present results in a more ethical, human-centered, and clinically respectful way.

This gives the project an important research contribution beyond AI prediction alone. It shows that the system is designed not only to analyze lesions, but also to communicate risk responsibly.
