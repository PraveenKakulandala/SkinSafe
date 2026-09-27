# Supervisor Discussion Brief

## SkinSafe Mobile Application Progress and Research Direction on Ethical Communication of Cancer-Related Warnings

**Project Title:** SkinSafe: Melanoma Skin Cancer Screening Support and Follow-Up Mobile Application  
**Prepared For:** Project Supervisor Discussion  
**Prepared By:** K. L. D. P. P. Kakulandala  
**Date:** August 13, 2026

---

## 1. Introduction

This document provides a formal update on the current progress of the SkinSafe mobile application and introduces an important research direction recommended for further discussion with the project supervisor. The first part of the document summarizes the technical and functional development progress of the application. The second part examines the ethical, psychosocial, and communication-related factors that doctors consider when informing patients about possible cancer-related findings. This second area is especially relevant to the application because SkinSafe does not merely generate a screening result; it also presents that result to the user. Therefore, the way the result is communicated is a significant research problem, not only a user interface problem.

---

## 2. Current Progress of the Mobile Application

The SkinSafe project has now progressed into a strong functional stage where the main workflows of the application are implemented and integrated. At this stage, the application can be described as a patient-centered melanoma screening-support mobile application with AI-assisted risk output, longitudinal lesion tracking, and educational support features.

### 2.1 Completed Functional Modules

The following major components are currently implemented:

#### 2.1.1 User Authentication and Access

- User registration using email and password
- User login and logout
- Forgot password flow
- Firebase-based authentication integration

#### 2.1.2 Guided Scan Workflow

- Patient details entry
- Selection of body area
- Lesion or mole label entry
- Questionnaire-based risk context collection
- Camera capture or gallery image upload

#### 2.1.3 AI-Supported Screening Flow

- Image selection and preparation for screening
- AI prediction flow integrated into the application
- Result display using patient-friendly wording
- Follow-up recommendation messaging

#### 2.1.4 History and Longitudinal Tracking

- Saving scan records to history
- Organizing history by patient name
- Filtering saved records by body area
- Tracking lesion spots separately
- Viewing longitudinal lesion timelines
- Comparing latest and previous saved visits for the same lesion

#### 2.1.5 Follow-Up Support Features

- Follow-up planning card on the dashboard
- Follow-up comparison support
- Ghost reference support for repeat lesion capture
- Guided 2-second stabilization flow for clearer capture

#### 2.1.6 Educational and Supportive Content

- Learn page with ABCDE guidance
- Melanoma-related educational content
- Prevention and UV-support content
- Profile page with privacy and safety information
- Medical safety disclosure before full app usage

---

## 3. Current Nature of the System

The project is currently positioned as a **screening-support and follow-up application**, not as a final clinical diagnostic authority. This distinction is important from both a technical and ethical perspective.

The application is designed to:

- support early attention to suspicious lesions
- guide users to perform structured self-monitoring
- help maintain lesion history over time
- encourage follow-up action when risk-related patterns appear
- present results in a calm, non-panic-inducing, ethically sensitive way

In other words, the application is not intended to replace dermatologists, biopsy, or specialist review. Instead, it is designed to support patients in a responsible, structured, and emotionally aware way.

---

## 4. Why the Communication of Serious Results Is a Research Problem

A key issue raised for further research is the following:

> When a doctor has to tell a patient that a result may indicate cancer, what factors must the doctor consider before delivering that warning, and how should the message be communicated?

This is a highly relevant question for the SkinSafe project because the application presents potentially sensitive health-related output to users. If the wording is too direct, alarming, or emotionally careless, the app could increase fear rather than support timely medical action. Therefore, this issue belongs not only to medicine, but also to:

- digital health ethics
- human-computer interaction
- patient-centered communication
- clinical psychology
- user experience design in healthcare

This means that the application’s result communication layer can become a major original contribution in the research.

---

## 5. Factors Doctors Consider Before Telling a Patient About Possible Cancer

When doctors communicate serious findings such as suspected cancer, they do not normally deliver the information in a purely technical manner. Instead, they consider multiple human, emotional, social, and situational factors.

### 5.1 Emotional and Psychological Condition of the Patient

One of the most important factors is the patient’s current emotional state. A patient may already be anxious, fearful, confused, or mentally overwhelmed even before hearing the result. If the doctor communicates the message too abruptly, the patient may panic, shut down emotionally, misunderstand the information, or fail to follow the next step properly.

Therefore, doctors generally consider:

- whether the patient is visibly distressed
- whether the patient seems emotionally prepared
- whether the patient has anxiety, shock, or denial
- whether the patient can process difficult information at that moment

This shows that the communication must be adapted to the patient’s psychological readiness, not only to the content of the result itself.

### 5.2 Health Literacy and Educational Understanding

Doctors also consider whether the patient can understand medical terminology. Many patients may not understand words such as:

- malignant
- lesion
- melanoma
- biopsy
- specialist referral

If the patient’s health literacy is limited, the doctor must use simpler, non-technical language and explain the meaning step by step. This is especially important in mobile health applications, because there is no doctor physically present to immediately clarify confusion.

### 5.3 Socioeconomic and Economic Factors

The patient’s economic situation can strongly affect how the information should be communicated and what practical recommendations can be made afterward. Even if the patient receives a serious warning, the ability to act on that warning may depend on:

- affordability of consultation
- travel cost
- access to specialists
- ability to miss work
- family financial dependence

Doctors therefore consider not only the seriousness of the finding, but also the realism of the next step. Ethical communication includes practical thinking, not only medical accuracy.

### 5.4 Social Support and Family Context

Some patients receive serious information better when a trusted family member or support person is present. Others prefer private communication first. Doctors often consider:

- whether the patient is alone
- whether the patient wants a family member involved
- whether there is a support network at home
- whether the patient is likely to cope better with help nearby

This is an important reminder that communication of bad news is not an isolated event. It takes place within a social context.

### 5.5 Culture, Religion, and Personal Beliefs

Patient expectations about how serious news should be communicated can vary depending on culture, religion, and family norms. Some patients prefer complete direct disclosure. Others prefer gradual explanation. Some expect relatives to be involved. Some value preservation of hope very strongly.

Therefore, doctors try to remain culturally sensitive and avoid assuming that every patient wants the same communication style.

### 5.6 Environment, Privacy, and Timing

Doctors also pay attention to the setting in which serious findings are communicated. Bad news should not be delivered carelessly in a crowded, noisy, rushed, or public environment. The communication setting matters because:

- privacy protects dignity
- calm surroundings reduce emotional overload
- time allows questions
- interruptions reduce trust and clarity

This factor is highly relevant to app design as well. A sensitive result should be displayed in a calm, respectful, and supportive interface rather than in a shocking or alarm-heavy visual form.

### 5.7 Patient Preference About Information

Not every patient wants the same amount of information immediately. Some want full detail. Others want a summary first. Some patients ask directly, “Is it cancer?” while others first want to know what should happen next.

Doctors therefore consider:

- how much the patient wants to know at that moment
- whether the patient wants a gradual explanation
- whether immediate next steps are more useful than technical detail

This is important in digital systems because result pages should support different levels of information depth rather than overwhelming every user instantly.

### 5.8 Urgency and Risk Level

Finally, the actual risk level affects how strongly and urgently the message should be communicated. Not every suspicious result requires the same level of urgency. A doctor balances:

- seriousness of the finding
- uncertainty in the evidence
- need for specialist review
- need for rapid action
- patient’s emotional tolerance

This is one reason why soft but action-oriented wording such as “Caution Advised” or “Specialist Review Recommended” can be more appropriate than alarming labels.

---

## 6. The SPIKES Protocol and Its Relevance

One of the best-known frameworks for communicating bad news in clinical care is the **SPIKES protocol**. This framework is highly relevant to the SkinSafe project because it offers a structured and ethically responsible model for result communication.

SPIKES stands for:

- **S** – Setting up the interview
- **P** – Assessing the patient’s Perception
- **I** – Obtaining the patient’s Invitation
- **K** – Giving Knowledge and information
- **E** – Addressing Emotions with empathy
- **S** – Strategy and Summary

### 6.1 Setting

The doctor ensures that the message is delivered in a private, calm, respectful setting.

### 6.2 Perception

The doctor first tries to understand what the patient already believes or suspects about the condition.

### 6.3 Invitation

The doctor checks how much information the patient wants at that point.

### 6.4 Knowledge

The doctor provides the information gradually and clearly, using understandable language.

### 6.5 Emotion and Empathy

The doctor acknowledges the patient’s emotional response rather than ignoring it.

### 6.6 Strategy and Summary

The doctor concludes with a practical plan, next actions, and reassurance that the patient is not being abandoned.

### 6.7 Why SPIKES Matters for SkinSafe

The SkinSafe application can be strengthened academically by using the logic of SPIKES as part of its digital result delivery approach. That means:

- the app should avoid panic-inducing language
- the app should deliver results using calm, supportive wording
- the app should provide clear next steps
- the app should acknowledge uncertainty
- the app should preserve user dignity and emotional safety

This creates a strong connection between clinical ethics and user interface design.

---

## 7. How This Research Direction Fits the Mobile Application

This research topic directly supports the originality of the project. The app is not only about machine learning or image classification. It is also about:

- how a sensitive result is presented
- how risk is translated into human language
- how emotional harm can be reduced
- how digital tools can imitate patient-centered clinical communication

This means the project can be positioned as:

> A melanoma screening-support mobile application that combines AI-based image analysis with ethical digital communication and structured follow-up support.

That is academically stronger than presenting the work only as an image classification application.

---

## 8. Possible Research Framing for the Supervisor Discussion

The following research framing can be discussed:

### 8.1 Main Extended Research Direction

> To investigate how cancer-related warnings should be communicated to patients in an ethical, empathetic, and patient-centered way, and how these principles can be incorporated into an AI-assisted melanoma screening mobile application.

### 8.2 Alternative Formal Statement

> To study the psychosocial, economic, and communication-related factors clinicians consider when delivering possible cancer warnings to patients, and to translate those principles into the result communication design of a mobile melanoma screening-support application.

### 8.3 Why This Is Valuable

This direction strengthens the project by adding:

- ethical depth
- healthcare realism
- psychological sensitivity
- stronger user-centered design justification
- stronger academic originality

---

## 9. Suggested Verbal Summary for the Supervisor

The following paragraph can be used in discussion:

> The SkinSafe mobile application has now reached a strong functional stage. The core modules such as authentication, guided scan workflow, AI-supported result presentation, history tracking, follow-up comparison, and patient education are already implemented. In addition to the technical progress, an important research direction is the ethical communication of possible cancer-related findings. Doctors do not simply tell patients that they may have cancer in a direct technical way; they consider the patient’s emotional state, health literacy, socioeconomic limitations, family support, cultural background, and readiness to receive difficult information. This is often explained through the SPIKES protocol for breaking bad news. I would like to use these principles as part of the application’s result communication design, so that the app does not only detect risk, but also presents it in a supportive, non-panic-inducing, and ethically appropriate manner.

---

## 10. Conclusion

The SkinSafe project has moved beyond the early concept stage and now includes a working multi-feature mobile application for guided lesion screening, lesion history tracking, AI-supported risk output, and follow-up support. However, one of the most meaningful research extensions now lies in how the application communicates sensitive health findings.

The supervisor’s suggestion to investigate how doctors deliver cancer-related warnings is highly relevant to the system. The evidence shows that such communication depends on much more than the medical result itself. Emotional condition, health literacy, economic limitations, family support, culture, timing, privacy, and urgency all influence how information should be delivered. The SPIKES protocol provides a structured and widely recognized clinical model that can guide this work.

Therefore, this research direction can become a major conceptual strength of the project by transforming the application from a purely technical screening tool into an ethically informed, patient-centered digital health system.

---

## 11. References

[1] National Cancer Institute, “Communication in Cancer Care (PDQ)–Health Professional Version,” National Cancer Institute, 2025. [Online]. Available: https://www.cancer.gov/about-cancer/coping/adjusting-to-cancer/communication-hp-pdq

[2] S. Monden et al., “Clinical Practice Guidelines on Breaking Bad News,” *Indian Journal of Palliative Care*, vol. 29, no. 4, 2023. [Online]. Available: https://pmc.ncbi.nlm.nih.gov/articles/PMC10096205/

[3] M. Bumb, S. Keefe, and K. Miller, “Breaking bad news: A guide for effective and empathetic communication,” *The Nurse Practitioner*, vol. 42, no. 11, pp. 14–17, 2017. [Online]. Available: https://pmc.ncbi.nlm.nih.gov/articles/PMC5578619/

[4] A. M. Holden et al., “The role of health literacy in cancer care: A mixed studies systematic review,” *Psycho-Oncology*, vol. 30, no. 9, pp. 1479–1490, 2021. [Online]. Available: https://pmc.ncbi.nlm.nih.gov/articles/PMC8589210/

[5] National Institute for Health and Care Excellence, “Shared decision making,” NICE Guideline NG197, 2021. [Online]. Available: https://www.nice.org.uk/guidance/ng197/chapter/recommendations
