# Melanoma Skin Cancer Detection and Prevention Mobile Application Using Machine Learning

Research Thesis

Presented to the Faculty of Computing

NSBM Green University

In partial fulfillment of the requirements for the degree of

BSc (Honours) in Software Engineering

By

K. L. D. P. P. Kakulandala

28510

Supervisor: Dr. Rasika Ranweera

2026

---

# Declaration

I declare that this thesis draft is based on my own project work carried out for the development of the SkinSafe melanoma skin cancer detection and prevention mobile application. The work described in this document has been prepared for academic review and may be further refined according to supervisor feedback, institutional formatting requirements, and final submission guidelines.

Student Name: K. L. D. P. P. Kakulandala

Student ID: 28510

Signature: ____________________________

Date: ________________________________

---

# Acknowledgement

I would like to express my sincere gratitude to my project supervisor, Dr. Rasika Ranweera, for the guidance, feedback, and academic direction provided throughout this research project. The supervisor discussions helped refine the project from a simple image classification idea into a broader mobile health application that considers screening support, prevention, follow-up tracking, and ethical communication of sensitive results.

I also acknowledge the support of the Faculty of Computing at NSBM Green University for providing the academic environment required to carry out this work. Finally, I am thankful to my family, friends, and peers who supported the practical development, testing, and improvement of the mobile application.

---

# Abstract

Melanoma is a serious form of skin cancer where delayed attention to suspicious skin lesions can increase health risk. Many people do not seek medical review early because they are uncertain whether a mole is dangerous, they lack awareness of warning signs, or they are afraid of cancer-related information. At the same time, smartphones and machine learning create an opportunity to provide structured self-monitoring support. However, a melanoma mobile application must be designed carefully because an uncertain artificial intelligence result can cause false reassurance or unnecessary panic if it is communicated incorrectly.

This research presents SkinSafe, a melanoma skin cancer detection and prevention mobile application developed using Flutter, Firebase, and machine learning. The application supports user registration, patient profile management, guided scan preparation, body-area and lesion-spot selection, questionnaire-based risk context collection, camera or gallery image input, on-device TensorFlow Lite image analysis, safe result communication, follow-up reminders, history tracking, visual body mapping, UV prevention guidance, and educational content. The system is designed as a screening-support and prevention application rather than as a replacement for dermatologist diagnosis or biopsy.

The machine learning component uses a binary melanoma-risk workflow. A MobileNetV2 transfer learning model was trained using HAM10000 dermoscopic images and later fine-tuned using a selected PAD-UFES-20 smartphone clinical image sample. The active mobile inference workflow uses a bundled TensorFlow Lite model with orientation correction, center crop, mild sharpening, resize preprocessing, and patient-safe threshold mapping. The latest selected-sample TFLite evaluation tested 312 clinical images and correctly warned 49 of 52 melanoma images while producing 46 false warnings among 260 non-melanoma images. This produced 84.3% selected-sample accuracy, 94.2% melanoma recall, 51.6% precision, and 82.3% specificity.

The main contribution of this project is not only image classification but the integration of artificial intelligence, mobile usability, longitudinal lesion history, prevention guidance, and ethical result delivery. The app avoids saying that a patient has cancer and instead provides graded action guidance such as retake recommended, low risk, monitor closely, caution advised, and specialist review recommended. Testing included model evaluation, Flutter static analysis, widget testing, debug APK builds, and emulator-based verification. The final artifact demonstrates a functional academic mobile health system suitable for screening support and further evaluation, while still requiring clinical validation before any medical-grade diagnostic use.

Keywords: melanoma, skin cancer, mobile health, machine learning, TensorFlow Lite, Flutter, Firebase, lesion tracking, prevention, ethical communication

---

# Table of Contents

[[TOC]]

---

# List of Tables

Table 1.1: Main SkinSafe scan workflow

Table 1.2: Resource requirements

Table 1.3: Project scope

Table 2.1: Existing system gap comparison

Table 3.1: Research design phases

Table 4.1: Stakeholder analysis

Table 4.2: Operationalization mapping

Table 4.3: Main system use cases

Table 4.4: Functional requirements

Table 4.5: Non-functional requirements

Table 5.1: Technology stack

Table 5.2: Active model configuration

Table 5.3: Result categories and actions

Table 6.1: Test plan summary

Table 6.2: Functional testing summary

Table 6.3: Current model evaluation metrics

Table 6.4: Selected-sample TFLite test result

Table 6.5: Confusion matrix and selected-sample performance

Table 6.6: False warning breakdown

Table 6.7: Build and code testing evidence

# List of Figures

Figure 1.1: SkinSafe rich picture and stakeholder workflow

Figure 3.1: Conceptual framework of the AI-supported screening workflow

Figure 4.1: SkinSafe main use case diagram

Figure 4.2: Proposed SkinSafe system architecture

Figure 4.3: Guided scan activity diagram

Figure 4.4: Core data model and class relationship diagram

Figure 5.1: Image scan analysis sequence diagram

Figure 5.2: SkinSafe Home dashboard interface

Figure 5.3: Guided scan interface

Figure 5.4: Scan history interface

Figure 5.5: Learn and prevention guidance interface

Figure 5.6: Profile and account interface

---

# Chapter 1 - Introduction

## 1.1 Chapter Overview

This chapter introduces the research project and explains the background of melanoma screening, the need for patient-centered prevention support, and the role of machine learning in a mobile health application. It presents the problem statement, research question, motivation, aim, objectives, proposed solution, resource requirements, project scope, and chapter summary. The chapter also positions the work as a screening-support and prevention application rather than as a definitive clinical diagnostic product.

## 1.2 Problem Background

Melanoma is one of the most dangerous types of skin cancer because it can progress aggressively if suspicious lesions are ignored or detected late. Early visual attention to changes in moles or skin spots is therefore important. Clinical assessment commonly considers warning signs such as asymmetry, border irregularity, color variation, diameter, and evolving change, often referred to as the ABCDE criteria [1]. Dermatologists also use dermoscopy and biopsy when a lesion requires professional assessment, and biopsy remains the final diagnostic standard [2].

In real life, many patients do not immediately visit a dermatologist when they notice a mole or lesion. Some people lack awareness of melanoma warning signs, some assume the lesion is harmless, and some delay because of fear, cost, travel difficulty, or limited access to specialist services [5]. This delay between noticing a visible skin change and seeking professional advice creates a practical healthcare problem. A mobile application cannot replace a dermatologist, but it can help users record lesions, understand warning signs, and take earlier follow-up action [6], [11].

Smartphones are widely available and provide cameras, storage, internet access, and notification support. These features make them useful for prevention-oriented mobile health applications [6], [11]. However, a cancer-related application must be designed carefully. If the app uses frightening words or presents the artificial intelligence result as a confirmed diagnosis, it can create anxiety, false reassurance, or inappropriate self-treatment [3], [4], [14]. Therefore, the challenge of this project is not only to classify an image, but also to guide capture, collect patient context, store history, provide reminders, and communicate results safely.

## 1.3 Problem Statement

The problem addressed by this research is the lack of a patient-centered mobile workflow that supports melanoma risk awareness, image-based screening support, lesion follow-up, prevention guidance, and ethical communication within one application. Many simple image scanning concepts focus mainly on the prediction result. This is not enough for melanoma-related self-monitoring because the user also needs guidance before the scan, clear next steps after the scan, and a way to compare the same lesion over time.

The software engineering problem is therefore to design and implement a mobile application that combines machine learning-based image review with patient details, questionnaire risk context, body-area selection, lesion labels, scan history, follow-up reminders, educational content, and safe result wording. The system must be useful for patients while clearly stating that it is not a medical diagnosis.

## 1.4 Research Question

The main research question of this project is: How can a machine learning-based mobile application be designed and implemented to support melanoma skin cancer detection and prevention through guided image analysis, patient-centered follow-up, and ethical result communication?

## 1.5 Research Motivation

The motivation for this research comes from both healthcare and software engineering perspectives. From the healthcare perspective, early awareness and responsible follow-up may encourage users to seek medical review sooner when a lesion changes or looks suspicious [1], [2]. From the software perspective, the project provides an opportunity to integrate mobile development, cloud services, machine learning, image preprocessing, user-centered design, and ethical communication into one working artifact [7], [11], [16].

A key motivation that emerged during supervisor discussions was the importance of how doctors communicate possible cancer-related warnings. Doctors consider the patient's emotional state, health literacy, economic situation, family support, cultural background, privacy, timing, and urgency before delivering serious information. This idea strongly influenced the app result screen, where the system avoids direct statements such as "you have cancer" and instead gives action-focused guidance based on risk level.

## 1.6 Research Aim

The aim of this research is to design, develop, and evaluate a melanoma skin cancer detection and prevention mobile application that uses machine learning to support lesion image review, prevention education, structured history tracking, follow-up reminders, and patient-safe result communication.

## 1.7 Research Objectives

1. To study melanoma screening concepts, early warning signs, prevention needs, and patient communication issues related to serious health information.
2. To review machine learning approaches for skin lesion image analysis and identify a suitable workflow for a mobile screening-support application.
3. To design a Flutter-based mobile application with authentication, patient details, guided scan preparation, questionnaire support, body-area selection, and image capture.
4. To train and integrate a binary melanoma-risk machine learning model using HAM10000 and selected PAD-UFES-20 data, and deploy the active model through TensorFlow Lite inside the mobile application.
5. To implement scan history, lesion spot tracking, follow-up reminders, visual body mapping, prevention guidance, and educational screens.
6. To evaluate the application using model metrics, functional test cases, static analysis, widget testing, debug APK builds, and emulator verification.
7. To present the result in a safe, non-diagnostic, patient-friendly manner that supports timely medical review instead of replacing clinical care.

## 1.8 Overview of the Developed Solution

The developed application is named SkinSafe. It is a Flutter mobile application that supports melanoma detection and prevention through a structured scan workflow. The user can create an account, complete onboarding, enter patient details, select a body area, label a lesion spot, answer screening questions, upload or capture a lesion image, and start the scan. After clicking scan, the image is preprocessed and analyzed by an on-device TensorFlow Lite model. The result is then converted into patient-safe action guidance and can be saved into history.

The current app contains the main navigation areas Home, Scan, History, Learn, and Profile. The Home screen summarizes follow-up needs and quick actions. The Scan screen contains the step-by-step scan workflow. The History screen organizes saved records by patient, body area, and lesion spot, including visual body map support. The Learn screen provides melanoma education and current UV prevention guidance. The Profile screen stores account details, baseline skin risk factors, privacy information, and theme preferences.

[[FIGURE:rich_picture]]

Table 1.1: Main SkinSafe scan workflow

| Step | Action in the application |
| --- | --- |
| 1 | User signs in or creates an account. |
| 2 | The app collects or loads patient details and baseline skin profile information. |
| 3 | The user selects a body area and lesion spot using a list or visual body map. |
| 4 | The user answers questionnaire items about recent change, growth, symptoms, family history, and previous concern. |
| 5 | The user captures or uploads a clear lesion image. |
| 6 | The image is preprocessed and analyzed using the TensorFlow Lite model inside the app. |
| 7 | The app combines model output, image quality, baseline factors, and questionnaire flags. |
| 8 | The app displays safe guidance and optional follow-up reminder settings. |
| 9 | The scan can be saved to history for later comparison. |

## 1.9 Resource Requirements

Table 1.2: Resource requirements

| Category | Resources used |
| --- | --- |
| Hardware | Development computer, Android emulator, optional Android phone, and local storage for datasets and model outputs. |
| Mobile development | Flutter, Dart, Android SDK, Android emulator, and Material 3 UI components. |
| Cloud and storage | Firebase Authentication, Cloud Firestore, local device storage, SharedPreferences profile cache, and local image file storage. |
| Machine learning | Python, TensorFlow, Keras, MobileNetV2 transfer learning, TensorFlow Lite, HAM10000 dataset, and selected PAD-UFES-20 clinical image sample. |
| Testing | Dart analyzer, Flutter widget tests, debug APK builds, emulator launch verification, and model evaluation CSV/JSON outputs. |

## 1.10 Project Scope

Table 1.3: Project scope

| In scope | Out of scope |
| --- | --- |
| Machine learning-based melanoma risk screening support | Confirmed cancer diagnosis or biopsy replacement |
| Camera/gallery image input and preprocessing | Hospital-grade image capture hardware |
| Patient details, body area, lesion label, and questionnaire flow | Automated treatment prescription |
| On-device TensorFlow Lite prediction | Regulated medical-device certification |
| History tracking, lesion timelines, comparison, and reminders | Guaranteed clinical accuracy for all real-world patients |
| Learn module with ABCDE, stages, FAQ, prevention, and UV guidance | Direct live dermatologist booking in the current version |

## 1.11 Chapter Summary

This chapter introduced the background, problem, aim, objectives, solution overview, resources, and scope of the SkinSafe project. The key idea is that the app supports screening and prevention by combining machine learning with safe communication and follow-up tracking. The next chapter reviews the literature that supports the clinical, technical, and human-centered design decisions used in the project.

---

# Chapter 2 - Literature Review

## 2.1 Introduction

This chapter reviews the literature and concepts that support the development of SkinSafe. The review focuses on melanoma warning signs, image-based skin lesion analysis, machine learning in medical imaging, mobile health application design, prevention and UV awareness, longitudinal lesion tracking, and ethical communication of possible cancer-related information.

## 2.2 Melanoma and Early Screening Concepts

Melanoma screening often begins with visual attention to suspicious lesions. The ABCDE rule is commonly used to explain early warning signs: asymmetry, border irregularity, color variation, diameter, and evolving change [1]. The evolving component is especially important because a mole that changes over time may require professional review. Dermoscopy improves specialist inspection, but ordinary users often begin with naked-eye observation, which can be inconsistent and influenced by fear or lack of knowledge [2].

A mobile application can support early screening by helping users document visible lesions and remember to recheck them [6], [11]. However, it should not claim to replace dermatologists. Clinical confirmation still requires professional assessment, and suspicious lesions may require biopsy [2]. Therefore, the literature supports the idea of using the app as an awareness, tracking, and escalation-support tool rather than as a final diagnostic system.

Prevention is also relevant because ultraviolet radiation exposure is a major skin-cancer risk factor and public health guidance commonly recommends reducing harmful sun exposure, using protective clothing, and following UV index advice [20], [22]. This supports the inclusion of prevention tips and current UV guidance in the Learn module.

## 2.3 Machine Learning for Skin Lesion Analysis

Deep learning has shown strong potential in skin lesion image classification. Esteva et al. demonstrated that deep neural networks can perform skin cancer classification at a level comparable to dermatologists under controlled dataset conditions [7]. The HAM10000 dataset is widely used for skin lesion classification research because it contains a large collection of multi-source dermatoscopic images [8]. ISIC challenge work also provides important benchmark context for lesion classification and segmentation research [9]. Broader medical imaging literature also shows that deep learning can support image interpretation tasks when datasets, validation, and clinical boundaries are handled carefully [10].

Although these studies show the promise of machine learning, they also highlight a limitation. Many public datasets are dermoscopic image datasets, while mobile users usually capture ordinary smartphone photos. This creates a domain gap. A model trained mainly on dermoscopic images may not behave the same way on phone-camera images [8], [12], [13]. For this reason, this project uses careful result wording and includes clinical-photo fine-tuning using a selected PAD-UFES-20 sample, which contains smartphone-collected clinical images and patient data [12]. The selected model architecture uses MobileNetV2 transfer learning because MobileNetV2 was designed for efficient mobile and embedded vision tasks [21].

## 2.4 TensorFlow Lite and Mobile Deployment

TensorFlow Lite is designed to run machine learning models on mobile and edge devices [16]. This is suitable for SkinSafe because normal scan analysis works inside the application without depending on a local Python server or internet connection. On-device inference can reduce latency, improve privacy, and make the app easier to demonstrate on an emulator or Android phone. In this project, the trained Keras model was exported to TensorFlow Lite and bundled as a Flutter asset.

The app preprocesses the image before inference. The selected image is decoded, orientation-corrected, center-cropped, mildly sharpened, resized to 224 x 224, and converted into the input format required by the model. The model then outputs a melanoma probability score. This score is not shown as a final diagnosis; it is mapped to patient-safe guidance categories, which follows the safety need identified in serious health communication and shared decision-making literature [3], [4], [15].

## 2.5 Mobile Health and User-Centered Design

Mobile health systems must be designed around user needs, trust, safety, and clarity. McCurdie et al. emphasize the importance of user-centered design in consumer mobile health applications [11]. Lupton also argues that mobile health apps should be examined critically because they influence how users understand their bodies and health responsibilities [6]. These ideas are important for SkinSafe because a skin cancer app can affect patient anxiety and decision-making, especially when the app gives risk-related information [3], [14], [15].

The UI design of SkinSafe therefore uses a calm medical color palette, clear step-by-step flow, simple wording, and action-focused result categories. The app avoids presenting unnecessary technical details to the patient during the scan flow. Instead, it guides the user through patient details, body area, questionnaire, photo selection, processing, result guidance, reminder, and history save.

## 2.6 Ethical Communication of Possible Cancer Warnings

A major research direction in this project is the ethical communication of sensitive results. In clinical practice, doctors do not normally deliver possible cancer information only as a technical statement. They consider the patient's emotional state, readiness, health literacy, economic situation, support system, culture, privacy, timing, and the urgency of the finding [3], [4], [14], [15].

The SPIKES protocol provides a structured approach for communicating bad news in healthcare: setting, perception, invitation, knowledge, emotion/empathy, and strategy/summary [3]. While SkinSafe is not a doctor, the same principles can influence digital result design. For example, the app sets a calm result screen, avoids diagnostic certainty, uses understandable language, acknowledges uncertainty, and provides a clear next action. This is why the result categories are written as guidance, such as "monitor closely" or "specialist review recommended," rather than as a direct cancer diagnosis.

## 2.7 Existing Systems and Research Gap

Existing skin lesion apps and research systems often focus on prediction or classification as the main output [7], [9], [13]. However, real patient support requires more than a single result. A user needs to know how to take a clear photo, how to track the same lesion, when to repeat a scan, what warning signs to learn, and when to seek medical care [1], [11], [15]. Existing systems may also provide insufficient support for ethical communication and longitudinal history.

Table 2.1: Existing system gap comparison

| Area | Common limitation in existing solutions | SkinSafe response |
| --- | --- | --- |
| Prediction-focused apps | Often emphasize a single risk output. | Combines AI output with patient context, questionnaire flags, and next-step guidance. |
| Image capture | Ordinary users may take inconsistent photos. | Provides guided scan preparation, photo quality checks, and follow-up spot labels. |
| History | Saved scans may not be organized by lesion. | Groups history by patient, body area, and lesion spot. |
| Communication | Risk messages may sound too certain or alarming. | Uses non-diagnostic, action-focused result categories influenced by patient communication principles. |
| Prevention | May not connect screening with daily prevention. | Includes Learn content and UV guidance for prevention awareness. |

## 2.8 Chapter Summary

The literature supports the need for a system that combines melanoma awareness, machine learning, mobile usability, follow-up tracking, and ethical communication. This project addresses the gap by developing a mobile application that treats AI scanning as one part of a broader prevention and patient-support workflow.

---

# Chapter 3 - Methodology

## 3.1 Introduction

This chapter explains the research methodology used to design, develop, and evaluate the SkinSafe mobile application. It describes the research paradigm, approach, design strategy, data sources, model development procedure, application development workflow, evaluation methods, reliability considerations, and ethical considerations.

## 3.2 Research Paradigm

The study follows a Design Science Research paradigm because the central output is a software artifact created to address a real-world problem. The artifact is not only a theoretical proposal; it is a working mobile application with integrated machine learning, Firebase services, scan history, prevention guidance, and testing evidence. Design Science Research is appropriate because the value of the study is demonstrated through construction, evaluation, and reflection on the artifact.

## 3.3 Research Approach

The project uses a pragmatic research approach. It combines clinical background knowledge, machine learning experimentation, software engineering, and user-centered design. This approach is suitable because the goal is not only to produce model metrics, but also to build a usable application that can guide patients through a safe screening-support workflow.

## 3.4 Research Design

The research design includes four connected phases. First, the melanoma screening and patient communication problem was studied. Second, requirements were defined for an application that supports detection, prevention, and follow-up. Third, the mobile application and machine learning model were implemented iteratively. Fourth, the system was evaluated using model metrics, functional testing, static analysis, widget testing, and emulator testing.

Table 3.1: Research design phases

| Phase | Main activity | Output |
| --- | --- | --- |
| Problem analysis | Study melanoma screening, app gaps, and ethical communication needs. | Problem statement, scope, and research question. |
| Requirement definition | Define patient flow, scan flow, history, prevention, and safety requirements. | Functional and non-functional requirements. |
| Artifact development | Build Flutter app, Firebase services, ML pipeline, TFLite integration, and UI refinements. | Working SkinSafe mobile application. |
| Evaluation | Run model evaluation, code analysis, widget tests, builds, and emulator verification. | Testing evidence and discussion of limitations. |

[[FIGURE:conceptual_framework]]

## 3.5 Data Collection and Dataset Preparation

The model development used secondary image datasets. HAM10000 was used as the base training dataset because it is a recognized public dermoscopic lesion dataset [8]. The classification problem was simplified into two classes: melanoma and non-melanoma. This binary approach matches the application goal of risk-oriented screening support rather than full clinical diagnosis.

To reduce the gap between dermoscopic training data and smartphone use, a selected PAD-UFES-20 clinical close-up sample was used for adaptation and testing. PAD-UFES-20 includes smartphone-collected clinical images and related patient data [12]. This was useful because the SkinSafe mobile app accepts phone-camera and gallery images, so clinical-photo testing is important for realistic evaluation.

## 3.6 Machine Learning Model Development

The machine learning pipeline used MobileNetV2 transfer learning [21]. Images were prepared at 224 x 224 resolution. The training workflow included data augmentation, class weighting for imbalance, validation monitoring, checkpointing, learning-rate reduction, and fine-tuning. The model was first trained using HAM10000 and then fine-tuned using selected PAD-UFES-20 clinical close-up images [8], [12]. The trained Keras model was exported to TensorFlow Lite for app integration [16].

The final active model configuration uses a melanoma binary task, classes non_melanoma and melanoma, image size 224 x 224, center_crop_sharpen preprocessing, model version ham10000-padufes-melanoma-binary-20260831T071059Z, caution threshold 0.45, borderline threshold 0.30, and specialist threshold 0.75. The validation-selected threshold was 0.375, but selected-sample retesting showed that 0.45 preserved strong melanoma warning performance while reducing unnecessary false warnings.

## 3.7 Mobile Application Development Method

The application was developed using Flutter and Dart [17]. Development followed an iterative Agile-style process where features were implemented, tested, reviewed, and refined [19]. The app was separated conceptually into five main navigation areas: Home, Scan, History, Learn, and Profile. Additional internal screens and components support patient selection, body-area selection, questionnaire, photo capture, processing, result review, lesion details, comparison, prevention content, and profile settings.

Firebase Authentication handles account access. Cloud Firestore stores scan metadata and patient-linked history [18]. Local device storage stores raw scan photos and generated lesion illustrations, while SharedPreferences is used for small persistent settings and profile backup. A cached user profile store was added so profile details such as age and contact are preserved locally even if Firestore permissions or network synchronization fail.

## 3.8 Image Scan Workflow Method

After the patient uploads or captures an image and clicks Scan, the app first validates that required information is available: patient name, age/contact, lesion label, and selected image. Then the selected image is decoded. The app applies orientation correction so that the image is interpreted correctly regardless of how the device stored the photo. The image is center-cropped to focus on the lesion area, mildly sharpened, resized to the model input size, and converted to an RGB tensor.

The TensorFlow Lite interpreter runs inside the mobile application using the bundled model asset. The model outputs a melanoma probability score. The app then evaluates photo quality and checks the model probability against threshold values. Finally, the app combines the AI result with questionnaire flags and baseline patient risk factors before generating patient-safe guidance. This process supports a more responsible workflow than directly showing only a raw probability value.

## 3.9 Evaluation Method

Evaluation was performed using both model-level and application-level methods. Model-level evaluation used accuracy, AUC, precision, recall, specificity, confusion matrix results, and selected-sample testing. Application-level evaluation used functional test cases, non-functional review, Dart analyzer checks, Flutter widget tests, debug APK builds, and emulator launch verification. The evaluation focuses on whether the application is technically functional and whether the AI output is suitable for screening-support wording.

## 3.10 Ethical Considerations

Ethical design is central to this project. The app does not tell the user that they have cancer. It provides screening-support guidance and encourages medical review when appropriate. The result wording was designed using principles from serious health communication and shared decision-making [3], [4], [14], [15]. The app also includes a safety note before scanning, a medical disclosure in the profile area, privacy information, and result categories that avoid diagnostic certainty.

## 3.11 Chapter Summary

This chapter explained the Design Science Research methodology, dataset preparation, model development, mobile app implementation, image scan workflow, evaluation methods, and ethical considerations. The next chapter defines the system requirements and architecture in more detail.

---

# Chapter 4 - System Requirement Specification

## 4.1 Chapter Overview

This chapter presents the system requirement specification for SkinSafe. It identifies stakeholders, functional requirements, non-functional requirements, major use cases, data requirements, architecture, and operational process flow. The purpose is to connect the research objectives with the implemented mobile application features.

## 4.2 Stakeholder Analysis

Table 4.1: Stakeholder analysis

| Stakeholder | Role or interest | System need |
| --- | --- | --- |
| Patient / user | Uses the app to record and review skin lesions. | Simple scan flow, understandable guidance, reminders, privacy, and history. |
| Caregiver or family member | May help the patient monitor lesions. | Clear instructions and safe wording that does not create panic. |
| Dermatologist / clinician | Potential reviewer of concerning lesions. | Useful history, body area, lesion spot, image timeline, and patient context. |
| Research student | Designs and evaluates the artifact. | Working implementation, model evidence, testing results, and documentation. |
| Supervisor / academic evaluator | Reviews academic quality and research contribution. | Clear methodology, requirements, implementation, evaluation, and limitations. |

## 4.3 Operationalization Process

The main concepts of the research were operationalized into app features. Melanoma awareness became Learn content and scan safety notes. Image-based risk analysis became the TensorFlow Lite scan service. Patient context became profile baseline factors and scan questionnaire flags. Longitudinal follow-up became patient/body-area/lesion history, comparison, visual body map, and reminders. Ethical communication became result categories and action-focused wording.

Table 4.2: Operationalization mapping

| Research concept | Application feature |
| --- | --- |
| Early lesion attention | Guided scan flow and reminder support. |
| ABCDE warning signs | Learn page educational content. |
| Machine learning risk support | On-device TensorFlow Lite model. |
| Patient risk context | Baseline profile and questionnaire flags. |
| Longitudinal tracking | History grouped by patient, body area, and lesion spot. |
| Safe communication | Result guidance without cancer diagnosis wording. |
| Prevention | UV card and prevention tips. |

## 4.4 System Use Cases

The major use cases of the application include account creation, login, password reset, patient profile completion, scan preparation, body-area selection, lesion spot selection, questionnaire completion, image capture, AI scan review, result viewing, follow-up reminder selection, saving history, opening patient history, viewing lesion timeline, comparing scans, reading prevention content, checking current UV guidance, editing profile details, and logging out.

Table 4.3: Main system use cases

| Use case | Actor | Description |
| --- | --- | --- |
| Create account | User | Registers with name, email, password, age, contact, and baseline skin profile details. |
| Start scan | User | Completes patient details, body area, lesion spot, questionnaire, and photo selection. |
| Analyze lesion image | System | Preprocesses the image and runs the TensorFlow Lite model. |
| Display safe result | System | Shows guidance category, summary, photo quality, recommended next step, and reminder options. |
| Save scan history | User/System | Stores scan metadata and local image references for future review. |
| Review history | User | Selects patient and body area, then opens lesion timeline and visit details. |
| Use visual body map | User | Selects or reviews lesion locations using a 3D/visual body map concept. |
| Read prevention guidance | User | Opens Learn content including ABCDE, stages, prevention, FAQ, and UV guidance. |

[[FIGURE:use_case]]

## 4.5 Functional Requirements

Table 4.4: Functional requirements

| ID | Requirement | Implemented status |
| --- | --- | --- |
| FR1 | The system shall allow users to register and log in using email and password. | Implemented |
| FR2 | The system shall collect patient name, age, contact, and baseline skin profile details. | Implemented |
| FR3 | The system shall allow users to select a body area and lesion spot before scanning. | Implemented |
| FR4 | The system shall provide a questionnaire for lesion change and risk context. | Implemented |
| FR5 | The system shall allow camera capture or gallery image upload. | Implemented |
| FR6 | The system shall preprocess and analyze the image using an on-device TFLite model. | Implemented |
| FR7 | The system shall show patient-safe result guidance and avoid diagnostic claims. | Implemented |
| FR8 | The system shall save scan metadata and image references to history. | Implemented |
| FR9 | The system shall group scan history by patient, body area, and lesion spot. | Implemented |
| FR10 | The system shall support follow-up reminders and comparison of saved scans. | Implemented |
| FR11 | The system shall provide educational content and UV-related prevention support. | Implemented |
| FR12 | The system shall preserve profile data locally if remote sync fails. | Implemented |

## 4.6 Non-Functional Requirements

Table 4.5: Non-functional requirements

| ID | Requirement | Implementation approach |
| --- | --- | --- |
| NFR1 | Usability | Step-by-step scan flow, simplified result page, clear labels, and patient-friendly wording. |
| NFR2 | Performance | On-device TFLite inference avoids normal dependency on a remote API. |
| NFR3 | Privacy | Local image storage and Firestore metadata design limit unnecessary data handling. |
| NFR4 | Reliability | Local profile cache and data-preserving run scripts reduce data loss during testing. |
| NFR5 | Maintainability | Feature folders, service classes, shared models, and reusable widgets support future updates. |
| NFR6 | Safety | Medical disclosure, safety note, non-diagnostic result categories, and doctor review guidance. |
| NFR7 | Accessibility | Readable color contrast, large touch targets, and simple language were prioritized. |

[[FIGURE:activity]]

## 4.7 Proposed System Architecture

The architecture is divided into presentation, application logic, service, storage, and machine learning layers. The presentation layer contains Flutter screens and reusable UI widgets. The application logic layer manages scan flow state, validation, result mapping, and navigation. The service layer contains scan prediction, image picking, image storage, scan record storage, profile storage, follow-up planning, lesion tracking, and UV forecast services. The storage layer uses Firebase Authentication, Cloud Firestore, local image files, and SharedPreferences. The machine learning layer uses the TensorFlow Lite model bundled with the app.

This architecture allows the project to separate UI responsibilities from data and prediction responsibilities. For example, the scan page calls a prediction service rather than directly managing the model interpreter. This improves maintainability and makes it easier to replace or improve the model later.

[[FIGURE:architecture]]

## 4.8 Data Requirements

The app stores user profile details, baseline skin profile flags, scan metadata, patient name, patient age, patient contact, body area, lesion spot label, notes, image source, model version, predicted class, risk score, image quality details, questionnaire flags, follow-up reminder settings, and local image paths. This data allows the app to reconstruct history and support follow-up comparison.

[[FIGURE:class_model]]

## 4.9 Chapter Summary

This chapter defined the system requirements and architecture. The requirements show that the project is not only an AI classifier, but a complete mobile workflow for screening support, prevention, history, reminders, and ethical result communication. The next chapter explains how these requirements were implemented.

---

# Chapter 5 - Implementation and Design

## 5.1 Chapter Overview

This chapter explains the implementation of the SkinSafe mobile application. It covers the technology stack, application modules, scan workflow, image preprocessing, TensorFlow Lite integration, result guidance, Firebase/local storage, history, body map, prevention features, UI/UX design, and implementation evidence.

## 5.2 Technology Stack

Table 5.1: Technology stack

| Technology | Purpose in the project |
| --- | --- |
| Flutter and Dart | Cross-platform mobile application development and UI implementation. |
| Material 3 | Modern mobile interface components, cards, buttons, forms, and navigation. |
| Firebase Authentication | Email/password account creation, login, password reset, and logout. |
| Cloud Firestore | Structured scan metadata and profile synchronization. |
| SharedPreferences | Local onboarding, theme preference, and cached profile backup. |
| Path Provider | Local device file paths for saved images. |
| Camera and Image Picker | Live camera capture and gallery selection. |
| Image package | Image decode, orientation correction, crop, sharpen, resize, and illustration processing. |
| TensorFlow / Keras | Model training and fine-tuning. |
| TensorFlow Lite / tflite_flutter | On-device model inference inside the Flutter app. |
| Model Viewer Plus | Interactive visual body map / 3D body reference support. |
| Geolocator and HTTP | Location and current UV prevention guidance support. |

## 5.3 Application Module Implementation

The app contains five main user-facing navigation areas. Home provides dashboard and follow-up planning. Scan provides the guided workflow. History shows saved patients, body areas, lesion timelines, visit details, and comparison. Learn provides ABCDE guidance, melanoma stage education, prevention tips, FAQ, and UV guidance. Profile shows account details, baseline skin profile, privacy and safety information, preferences, and logout support.

The codebase also includes separate feature folders for dashboard, scan, history, learn, profile, authentication, onboarding, shared widgets, shared models, and services. This structure supports easier future updates compared with keeping all pages as one large UI file. The main app currently renders through the SkinSafe frontend integration while feature folders document the intended modular structure.

## 5.4 Account and Profile Implementation

The account flow supports sign-up, sign-in, password reset, and logout. During account creation, the app collects name, email, password, age, contact, skin reaction type, and baseline risk factors such as many or unusual moles, sunburn/tanning history, family skin cancer history, and previous skin cancer concern. These details help the app prefill scan patient details and provide context-aware result guidance.

A profile persistence improvement was added because Firestore permission or synchronization problems can cause remote profile reads to fail. The app now uses a cached profile store that saves profile details locally first and then attempts remote synchronization. When remote data is blank but local cached values exist, non-empty local age and contact values are preserved. This makes the app more reliable during emulator testing and offline or permission-limited scenarios.

## 5.5 Guided Scan Workflow Implementation

The scan workflow is separated into four preparation steps. Step 1 collects patient details. Step 2 selects the body area and lesion spot. Step 3 collects screening questionnaire answers. Step 4 captures or uploads a clear photo. The app validates required fields before moving forward, so the user cannot continue without essential patient and lesion information. A scan safety note is shown before scanning to remind users that AI output is guidance, not diagnosis.

The scan page was simplified during UI refinement. Earlier technical toggles such as auto capture preview, lighting support, and follow-up alignment were removed from the patient-facing step because they created unnecessary visual clutter. The current step focuses on choosing a camera or gallery image and gives simple guidance: use a clear, close, well-lit image with the lesion centered.

## 5.6 Image Preprocessing and TensorFlow Lite Inference

After the user clicks Scan, the app decodes the selected image and applies orientation correction. The image is then center-cropped to a square, mildly sharpened using an unsharp mask, resized to 224 x 224, and converted to RGB input values for the TensorFlow Lite model. The preprocessing mode used by the active app model is center_crop_sharpen.

The TensorFlow Lite interpreter is loaded from the app asset path ml/output/melanoma_risk_classifier.tflite. The model configuration is loaded from ml/output/model_config.json. The interpreter runs with two threads and outputs a melanoma probability value. The app calculates non-melanoma probability and confidence from this output, then maps the result into a patient-safe predicted class and status category based on threshold settings.

[[FIGURE:scan_sequence]]

Table 5.2: Active model configuration

| Model element | Current value |
| --- | --- |
| Task | Binary melanoma risk classification |
| Classes | non_melanoma and melanoma |
| Image size | 224 x 224 |
| Model version | ham10000-padufes-melanoma-binary-20260831T071059Z |
| Base training data | HAM10000 dermoscopic images |
| Adaptation data | Selected PAD-UFES-20 clinical close-up sample |
| Preprocessing | Orientation correction, center crop, mild sharpening, resize |
| Active caution threshold | 0.45 |
| Specialist threshold | 0.75 |
| Deployment method | Bundled TensorFlow Lite model inside the mobile app |

## 5.7 Result Communication Implementation

The result page is designed around action guidance rather than fear. The app does not display a message saying that the user has cancer. Instead, the output is grouped into categories such as retake recommended, low risk, monitor closely, caution advised, and specialist review recommended. Each category has a next step. For example, low-risk results are saved as a baseline with routine self-check guidance, while specialist review recommended results tell the user not to wait for another app scan and to arrange clinician review.

Table 5.3: Result categories and actions

| Result type | Application action |
| --- | --- |
| Retake recommended | Ask the user to take a clearer photo immediately before relying on the result. |
| Low risk | Save as a baseline scan and support routine monthly self-check reminders. |
| Monitor closely / uncertain | Suggest saving and re-scanning the same mole in 7 to 14 days. |
| Caution advised | Advise doctor or dermatologist review and allow a short follow-up reminder. |
| Specialist review recommended | Show urgent red guidance: do not wait for app re-scan; arrange specialist review. |

The result page also combines AI output with image quality, patient baseline risk factors, and questionnaire flags. This helps avoid treating the model probability as the only decision point. It also aligns with the ethical communication approach discussed in the literature review.

## 5.8 History, Lesion Tracking, and Reminder Implementation

The History section is designed to show patient names first. After selecting a patient, the app shows saved body areas that contain mole or lesion records. When a body area is opened, the user can view lesion spots and saved scan visits. This design prevents the history page from becoming overloaded and supports the user requirement that history should initially show only the patient and relevant body areas.

Each saved scan contains patient details, body area, lesion spot, timestamp, model result, risk score, questionnaire flags, baseline summary, image quality details, follow-up reminder settings, and local image references. If a result requires monitoring, the app can schedule or store a reminder window, commonly 7 to 14 days for uncertain or closely monitored lesions. Low-risk baseline records can support longer routine self-check reminders.

## 5.9 Visual Body Map and 3D Body Reference

The app includes visual body area selection and history visualization. In the scan flow, the user can choose the body area from a dropdown list or open a visual body map. In history, a visual display mode can show body areas and lesion markers. A 3D medical mannequin asset was added to support a more modern and interactive body reference. The body map is useful because patients may remember a mole visually more easily than through text labels alone.

The current body map is a functional medical reference rather than a photorealistic anatomical model. It supports body area selection and interaction, but future work can improve the model asset quality, anatomical realism, rotation, marker placement, and lesion coordinate storage.

## 5.10 Learn, Prevention, and UV Guidance

The Learn section provides educational material on ABCDE signs, melanoma stages, prevention tips, and frequently asked questions. Prevention was emphasized because melanoma support should not begin only after a suspicious lesion is found. UV guidance was added so the user can see current UV risk and receive daily prevention advice such as avoiding strong sunlight, using sunscreen, wearing protective clothing, and monitoring exposure time.

The UV feature uses live fetch and fallback logic. It is intended as prevention awareness rather than a certified weather service. The result is displayed using simple risk colors and user-friendly wording, based on public health UV-risk communication principles [22].

## 5.11 UI/UX Design Implementation

The UI was refined to fit a medical application. The color theme moved toward calm blue-green and teal tones with optional dark mode. Cards, buttons, spacing, shadows, and navigation were simplified for readability. The bottom navigation uses a liquid glass visual style with draggable interaction and clearer selected state. The scan and result screens were simplified to remove unnecessary UI elements and focus on patient actions.

The result screen was especially important. Instead of showing too many visuals or technical details, the current design emphasizes the result category, short summary, compact scan details, recommended next step, reminder setting, and patient context. Low-risk results hide unnecessary lesion illustration visuals to reduce confusion.

[[FIGURE:home]]

[[FIGURE:scan]]

[[FIGURE:history]]

[[FIGURE:learn]]

[[FIGURE:profile]]

## 5.12 Chapter Summary

This chapter explained the implementation of the SkinSafe application, including account management, guided scan flow, image preprocessing, TensorFlow Lite inference, safe result communication, history, body map, reminders, prevention content, and UI improvements. The next chapter evaluates the system through testing and model results.

---

# Chapter 6 - Testing and Evaluation

## 6.1 Chapter Overview

This chapter presents the testing and evaluation carried out for the SkinSafe application. Testing covered the machine learning model, image preprocessing behavior, functional app workflows, non-functional quality, static analysis, widget testing, debug build verification, emulator testing, and known limitations.

## 6.2 Test Plan

The test plan was designed to verify whether the application performs its core tasks correctly: account access, profile persistence, scan preparation, image input, AI review, result display, save to history, history browsing, reminders, Learn content, UI navigation, and emulator execution. Model testing focused on melanoma warning performance and false warning behavior because the app is intended for screening support.

Table 6.1: Test plan summary

| Test area | Purpose | Method |
| --- | --- | --- |
| Authentication | Verify sign-up, login, password reset, and logout. | Manual app testing and Firebase-connected flow checks. |
| Profile persistence | Ensure age/contact and baseline flags are preserved. | Cached profile store testing and analyzer verification. |
| Scan workflow | Verify step validation and image selection. | Manual scan flow and UI validation checks. |
| AI inference | Verify TFLite model loads and returns result categories. | Model output testing and app scan flow testing. |
| History | Verify saved records are grouped by patient, body area, and lesion. | Manual history review and data model verification. |
| UI navigation | Verify Home, Scan, History, Learn, Profile navigation. | Emulator testing and screenshot review. |
| Build quality | Verify app compiles and tests pass. | Dart analyzer, Flutter widget tests, debug APK build. |

## 6.3 Functional Testing Summary

Table 6.2: Functional testing summary

| Function | Expected result | Observed result |
| --- | --- | --- |
| Create account | User can create account with profile details. | Implemented; local profile backup added for age/contact reliability. |
| Login | Existing user can sign in. | Implemented and tested through emulator flow. |
| Guided scan steps | User completes patient, body area, questionnaire, and photo steps. | Implemented with validation before moving forward. |
| Image upload/capture | User can select camera or gallery image. | Implemented using camera and image picker packages. |
| TFLite scan | App analyzes selected image on device. | Implemented using bundled TensorFlow Lite asset. |
| Result guidance | App displays safe category and next step. | Implemented with non-diagnostic action wording. |
| Save to history | Scan record is saved for later review. | Implemented with metadata and local image references. |
| History body area view | Patient selected first, then body areas with saved moles are shown. | Implemented. |
| Reminder support | User can enable follow-up reminder based on result category. | Implemented in result and dashboard planning flow. |
| Learn / UV | User can read education and prevention guidance. | Implemented with current UV card and prevention content. |

## 6.4 Machine Learning Evaluation

The active model was evaluated using the latest model configuration and selected clinical-photo sample. The held-out PAD split metrics from the current output show accuracy of 0.8085, AUC of 0.9263, loss of 0.4225, precision of 0.4667, and recall of 0.8750. These values indicate that the model learned useful melanoma-related patterns, but precision remains moderate, meaning false warnings are still expected.

Table 6.3: Current model evaluation metrics

| Metric | Value |
| --- | --- |
| Accuracy | 0.8085 |
| AUC | 0.9263 |
| Loss | 0.4225 |
| Precision | 0.4667 |
| Recall | 0.8750 |
| Validation-selected threshold | 0.3750 |
| Active patient-facing caution threshold | 0.4500 |

A selected-sample TFLite check was also performed using 312 PAD-UFES-20 clinical close-up images. At the active app threshold of 0.45 with center_crop_sharpen preprocessing, the app warned 49 out of 52 melanoma images and missed 3 melanoma images. Among 260 non-melanoma images, 214 were treated as lower risk and 46 produced false warnings.

Table 6.4: Selected-sample TFLite test result

| Actual image group | Total images | Correct result | Wrong result | Meaning |
| --- | --- | --- | --- | --- |
| Melanoma images | 52 | 49 | 3 | 49 melanoma images were correctly warned; 3 were missed. |
| Non-melanoma images | 260 | 214 | 46 | 214 non-melanoma images stayed below caution level; 46 were false warnings. |

Table 6.5: Confusion matrix and selected-sample performance

| Metric | Count or value |
| --- | --- |
| True positives | 49 |
| False negatives | 3 |
| True negatives | 214 |
| False positives | 46 |
| Selected-sample accuracy | 84.3% |
| Melanoma recall / catch rate | 94.2% |
| Precision | 51.6% |
| Specificity | 82.3% |

## 6.5 Interpretation of False Warnings

The false warnings are mainly caused by the similarity between some non-melanoma lesions and melanoma-like visual patterns. Basal cell carcinoma, squamous cell carcinoma, actinic keratosis, seborrheic keratosis, and some nevi may show irregular color, border, or texture. Since the app is tuned for screening support and prioritizes melanoma recall, the threshold is intentionally cautious. This reduces the chance of missing suspicious cases but increases false positives.

In a viva or supervisor discussion, this can be explained honestly: the model is not expected to be 100% accurate because it is trained on limited public datasets and tested on clinical images that vary in lighting, angle, focus, and lesion type. The design response is to use safe categories and doctor-review guidance rather than diagnostic claims. Therefore, false warnings are handled as a safety trade-off in a screening-support application.

Table 6.6: False warning breakdown

| Non-melanoma diagnosis group | Tested images | False warnings |
| --- | --- | --- |
| Basal cell carcinoma | 52 | 8 |
| Nevus | 52 | 10 |
| Seborrheic keratosis | 52 | 10 |
| Solar or actinic keratosis | 52 | 8 |
| Squamous cell carcinoma | 52 | 10 |

## 6.6 Application Build and Code Testing

Static and automated tests were used to verify that the project compiles and that the basic widget path works. The Dart analyzer was run against the main frontend and profile store files, and no issues were found after the latest UI and profile persistence changes. Flutter widget testing was executed with the command flutter test --no-pub, and the available widget test passed. Debug APK builds were also completed successfully using the configured Flutter SDK path.

Table 6.7: Build and code testing evidence

| Check | Command or method | Result |
| --- | --- | --- |
| Static analysis | dart analyze lib/app/skinsafe_frontend.dart lib/services/firebase/user_profile_store.dart | No issues found |
| Widget test | flutter test --no-pub | All tests passed |
| Debug build | flutter build apk --debug | Build successful |
| Emulator install | flutter install/run and adb launch | App launched on emulator |
| Black screen fix | Android emulator rendering adjustment | UI loaded after disabling Impeller for emulator compatibility |
| Data preservation | run_flutter_emulator.ps1 and install_debug_preserve_data.ps1 | Run/install workflow updated to avoid clearing local data unnecessarily |

## 6.7 Non-Functional Evaluation

Usability was improved through step separation, simplified scan UI, clearer result layout, and consistent medical color styling. Performance was improved by using on-device TensorFlow Lite inference for normal scanning rather than depending on a running Python API. Privacy was improved by using local image storage and structured metadata rather than requiring cloud image upload for normal flow. Reliability was improved by adding local profile caching and data-preserving run scripts. Maintainability was supported through service classes, models, feature folders, and reusable UI components.

## 6.8 Limitations of Testing

The current testing has important limitations. The model was not clinically validated with a large real-world patient population. The selected PAD-UFES-20 sample improves realism but is still limited in size. The model is binary and does not provide full differential diagnosis. Image quality varies greatly when ordinary phone photos are used. User testing and psychological impact testing were not completed at large scale. Therefore, the app should be presented as a functional academic screening-support application and not as a clinically certified diagnostic system.

## 6.9 Chapter Summary

This chapter presented model evaluation, selected-sample testing, false warning interpretation, functional testing, build checks, and non-functional evaluation. The results show that the application works as an integrated system and that the model has strong melanoma recall in the selected sample, but further data, validation, and clinical review are required for higher confidence.

---

# Chapter 7 - Concluding Remarks

## 7.1 Accomplishment of Research Objectives

The project achieved its main objective of designing and implementing a melanoma skin cancer detection and prevention mobile application using machine learning. The final artifact includes authentication, patient details, baseline risk profile, guided scan preparation, body-area and lesion-spot selection, questionnaire support, image capture or upload, image preprocessing, on-device TensorFlow Lite inference, safe result guidance, follow-up reminders, scan history, visual body map support, educational content, UV prevention guidance, profile management, and testing evidence.

The research also achieved the objective of integrating ethical communication into a technical application. The result screen was designed not to diagnose cancer directly, but to provide patient-safe action categories. This makes the project stronger than a simple classifier because it considers how users may emotionally and practically respond to the result.

## 7.2 Problems Encountered

Several problems were encountered during the project. The first was model accuracy limitation. Public skin lesion datasets are useful, but dermoscopic images differ from ordinary mobile phone images. This caused a need for fine-tuning and selected-sample testing. The second problem was false warnings. Some non-melanoma lesions visually resemble suspicious melanoma-like patterns, especially when using a cautious threshold. The third problem was mobile integration complexity, including camera handling, emulator rendering issues, Firebase permissions, local profile persistence, and TensorFlow Lite asset integration.

UI complexity was another challenge. Early scan and result screens contained unnecessary elements, so the interface was simplified to improve patient usability. The 3D body map also showed that realistic medical visualization depends on high-quality 3D assets and careful interaction design. These issues were addressed partially, but further refinement remains valuable.

## 7.3 Self-Reflection

This project strengthened practical understanding of full-stack mobile application development, machine learning integration, and healthcare-oriented user experience design. It showed that a health application cannot be judged only by whether the model gives a prediction. The workflow, wording, reminders, data structure, and user confidence are equally important. The most valuable learning was the need to balance technical ambition with ethical responsibility.

Another learning point was the importance of honest evaluation. A model with strong recall can still have false positives, and a visually attractive interface can still confuse users if it includes too many features. The project therefore required repeated refinement, testing, and simplification. This reflects real software engineering practice, where the best solution is often the one that is safe, understandable, maintainable, and useful.

## 7.4 Business and Real-World Insight

SkinSafe has potential as a prevention and follow-up support tool for users who want to monitor skin lesions more responsibly. It could be useful in awareness campaigns, personal self-monitoring, community health education, and pre-consultation record keeping. The history and lesion tracking features may help users communicate more clearly with clinicians by showing when a lesion was first scanned, where it is located, and how it changed over time.

However, real-world deployment requires careful positioning. The app should be marketed as screening support and prevention guidance, not as a cancer diagnosis app. Before public clinical claims are made, the system would require larger dataset validation, medical expert review, privacy policy completion, release signing, store compliance checks, and possibly regulatory evaluation depending on the claims made.

## 7.5 Future Recommendations

1. Expand the clinical-phone-image dataset and evaluate the model with more diverse skin tones, lighting conditions, devices, and lesion types.
2. Improve image quality validation to reject blurry, too-distant, overexposed, underexposed, or non-skin images before prediction.
3. Improve calibration and threshold tuning so the app can reduce false warnings while preserving high melanoma recall.
4. Add clinician review input to refine result wording and follow-up guidance.
5. Conduct usability testing with real users to evaluate whether the scan flow is easy to understand.
6. Evaluate psychological impact to ensure result messages support action without unnecessary panic.
7. Improve the 3D body map using a higher-quality medical model and coordinate-based lesion marker placement.
8. Prepare production release requirements such as final app ID, privacy policy, release signing, and app store declarations.

## 7.6 Final Conclusion

The SkinSafe project successfully demonstrates a machine learning-based melanoma skin cancer detection and prevention mobile application. The system integrates mobile development, on-device AI analysis, patient data, questionnaire context, follow-up reminders, lesion history, visual body mapping, UV prevention, educational content, and ethical communication. Testing shows that the current model is useful for screening support, especially because it achieved a high melanoma warning rate in the selected sample. At the same time, the presence of false warnings and the absence of clinical validation mean that the application must remain clearly positioned as a support tool.

The final contribution of the project is the design of a practical, patient-centered workflow that treats artificial intelligence as one part of a safer health-support experience. The app helps users organize information, understand risk, take follow-up action, and know when to seek medical review. With further clinical validation and production preparation, SkinSafe can be extended into a stronger real-world prevention and monitoring platform.

---

# References

[1] D. S. Rigel, R. J. Friedman, A. W. Kopf, and D. Polsky, "ABCDE - an evolving concept in the early detection of melanoma," Archives of Dermatology, vol. 141, no. 8, pp. 1032-1034, 2005. Available: https://pubmed.ncbi.nlm.nih.gov/16103334/

[2] M. E. Vestergaard, P. Macaskill, P. E. Holt, and S. W. Menzies, "Dermoscopy compared with naked eye examination for the diagnosis of primary melanoma," British Journal of Dermatology, vol. 159, no. 3, pp. 669-676, 2008. Available: https://pubmed.ncbi.nlm.nih.gov/18616769/

[3] W. F. Baile, R. Buckman, R. Lenzi, G. Glober, E. A. Beale, and A. P. Kudelka, "SPIKES - A six-step protocol for delivering bad news: application to the patient with cancer," The Oncologist, vol. 5, no. 4, pp. 302-311, 2000. Available: https://pubmed.ncbi.nlm.nih.gov/10964998/

[4] L. Fallowfield and V. Jenkins, "Communicating sad, bad, and difficult news in medicine," The Lancet, vol. 363, no. 9405, pp. 312-319, 2004. Available: https://pubmed.ncbi.nlm.nih.gov/14738786/

[5] L. G. Gordon and D. Rowell, "Health system costs of skin cancer and cost-effectiveness of skin cancer prevention and screening," European Journal of Cancer Prevention, vol. 24, no. 2, pp. 141-149, 2015. Available: https://pubmed.ncbi.nlm.nih.gov/25089375/

[6] D. Lupton, "Apps as artefacts: Towards a critical perspective on mobile health and medical apps," Societies, vol. 4, no. 4, pp. 606-622, 2014. Available: https://www.mdpi.com/2075-4698/4/4/606

[7] A. Esteva et al., "Dermatologist-level classification of skin cancer with deep neural networks," Nature, vol. 542, no. 7639, pp. 115-118, 2017. Available: https://www.nature.com/articles/nature21056

[8] P. Tschandl, C. Rosendahl, and H. Kittler, "The HAM10000 dataset, a large collection of multi-source dermatoscopic images of common pigmented skin lesions," Scientific Data, vol. 5, p. 180161, 2018. Available: https://www.nature.com/articles/sdata2018161

[9] N. Codella et al., "Skin Lesion Analysis Toward Melanoma Detection: A Challenge Hosted by the International Skin Imaging Collaboration (ISIC)," arXiv:1902.03368, 2019. Available: https://arxiv.org/abs/1902.03368

[10] M. A. Mazurowski, M. Buda, A. Saha, and M. R. Bashir, "Deep learning in medical imaging: The state of the art," International Journal of Computer Assisted Radiology and Surgery, vol. 14, pp. 1449-1463, 2019. Available: https://pubmed.ncbi.nlm.nih.gov/30468663/

[11] C. R. McCurdie et al., "mHealth consumer apps: The case for user-centered design," Biomedical Instrumentation and Technology, vol. 46, no. s2, pp. 49-56, 2012. Available: https://pubmed.ncbi.nlm.nih.gov/23039777/

[12] A. G. C. Pacheco et al., "PAD-UFES-20: a skin lesion dataset composed of patient data and clinical images collected from smartphones," Data in Brief / Mendeley Data, 2020. Available: https://arxiv.org/abs/2007.00478

[13] V. Rotemberg et al., "A patient-centric dataset of images and metadata for identifying melanomas using clinical context," arXiv:2008.07360, 2020. Available: https://arxiv.org/abs/2008.07360

[14] National Cancer Institute, "Communication in Cancer Care (PDQ) - Health Professional Version," 2025. Available: https://www.cancer.gov/about-cancer/coping/adjusting-to-cancer/communication-hp-pdq

[15] National Institute for Health and Care Excellence, "Shared decision making," NICE Guideline NG197, 2021. Available: https://www.nice.org.uk/guidance/ng197/chapter/recommendations

[16] TensorFlow, "TensorFlow Lite guide," Google. Available: https://www.tensorflow.org/lite/guide

[17] Flutter, "Flutter documentation," Google. Available: https://docs.flutter.dev/

[18] Firebase, "Firebase documentation," Google. Available: https://firebase.google.com/docs

[19] K. Schwaber and J. Sutherland, "The Scrum Guide," 2020. Available: https://scrumguides.org/scrum-guide.html

[20] World Health Organization, "Global action plan for the prevention and control of noncommunicable diseases 2013-2020," WHO, 2013. Available: https://www.who.int/publications/i/item/9789241506236

[21] M. Sandler, A. Howard, M. Zhu, A. Zhmoginov, and L. C. Chen, "MobileNetV2: Inverted residuals and linear bottlenecks," arXiv:1801.04381, 2018. Available: https://arxiv.org/abs/1801.04381

[22] World Health Organization, World Meteorological Organization, United Nations Environment Programme, and International Commission on Non-Ionizing Radiation Protection, "Global Solar UV Index: A practical guide," WHO, 2002. Available: https://www.who.int/publications/i/item/9241590076
