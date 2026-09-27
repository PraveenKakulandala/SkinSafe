# INTERIM SUBMISSION - 02

## Melanoma Skin Cancer Screening Support and Follow-Up Mobile Application Using Machine Learning

**Student:** K. L. D. P. P. Kakulandala  
**Student ID:** 28510  
**Degree Program:** BSc (Honours) in Software Engineering  
**Institution:** NSBM Green University  
**Project Status Date:** August 10, 2026

---

## Chapter 01: Introduction

### 1.1 Chapter Overview

This chapter introduces the updated context of the research study and aligns the report with the software artifact that has already been implemented. Unlike the first interim submission, which mainly presented the proposed concept, this second interim reflects the current state of development of the melanoma screening-support mobile application. The chapter outlines the clinical and technical background of the problem, defines the refined problem statement, presents the research question, and describes the aim, objectives, scope, and practical boundaries of the developed system.

### 1.2 Problem Background

Melanoma is one of the most dangerous forms of skin cancer because delayed detection can lead to rapid progression and a significantly poorer prognosis. Early identification of suspicious lesions remains critically important, especially when visible skin changes are still limited to early stages. In practice, however, many patients delay seeking professional support due to fear, low awareness, limited access to dermatological services, and uncertainty about whether a visible lesion is serious enough to justify consultation. This gap between the first visual sign and the first clinical action remains a major challenge in skin cancer care [1], [2], [14].

The increasing availability of smartphones creates an opportunity to provide a structured digital screening-support tool that can encourage earlier attention to suspicious lesions. However, a skin cancer application must be designed carefully. If such a system provides alarming wording, unreliable image capture, or unclear next steps, it can increase anxiety rather than support responsible action. Therefore, the technical challenge is not only image analysis but also safe communication, guided capture, structured follow-up, and realistic clinical positioning [3], [4], [6].

### 1.3 Problem Statement

The broader problem addressed by this research is the delay between the early visual appearance of suspicious skin lesions and the patient seeking professional dermatological review. Existing mobile health solutions often focus heavily on algorithmic prediction but do not adequately support user confidence, ethical communication, or consistent longitudinal tracking.

From a software engineering perspective, the specific problem is the absence of a patient-centered mobile system that combines the following elements in a single workflow:

- guided lesion image capture
- safe and non-diagnostic risk communication
- storage of lesion history for future comparison
- machine learning-based melanoma risk screening
- structured follow-up support after a result is produced

This research therefore focuses on building a melanoma screening-support application rather than a definitive diagnostic tool. The system is intended to guide users toward better self-monitoring and timely professional review, while clearly acknowledging that clinical biopsy remains the gold standard [1], [2].

### 1.4 Research Question

The updated research is guided by the following question:

**How can a machine learning-based mobile application be designed and implemented to support melanoma screening, structured lesion follow-up, and ethical result communication while remaining practical for real-world patient use?**

### 1.5 Research Motivation

This study is motivated by the need to bridge the delay between symptom recognition and professional medical consultation. A well-designed mobile application can support early awareness, reduce unstructured self-interpretation, and encourage safer follow-up behavior. In addition, the project addresses an important software engineering challenge: integrating a machine learning workflow, guided camera interaction, longitudinal record management, and empathetic medical messaging into one coherent mobile application. The motivation of this project is therefore both clinical and technical.

### 1.6 Research Aim

The primary aim of this research is to design, develop, and evaluate a mobile application that supports melanoma risk screening, follow-up image tracking, and ethical communication of results through an accessible patient-centered workflow.

### 1.7 Research Objectives

The objectives of the updated study are:

1. To investigate the clinical and psychological issues associated with melanoma awareness, delayed consultation, and communication of concerning health information.
2. To review literature related to melanoma screening, machine learning for skin lesion analysis, ethical digital health communication, and user-centered mobile health design.
3. To design and implement a Flutter-based mobile application that supports guided image capture, lesion record storage, patient-centered follow-up, and educational content.
4. To develop a machine learning pipeline using the HAM10000 dataset for binary melanoma-risk screening and integrate the prediction workflow with the mobile application.
5. To evaluate the implemented prototype using available model performance metrics and functional verification of the end-to-end software workflow.

### 1.8 Current Overview of the Developed Solution

The current artifact is a working Flutter mobile application named **SkinSafe**. The system now includes Firebase authentication, onboarding, a one-time medical safety acknowledgement, guided scan capture, image upload, local machine learning prediction through an API, history storage, follow-up planning, educational content, and longitudinal lesion comparison.

The implemented scan workflow includes the following sequence:

1. user registration or sign-in
2. onboarding and medical safety acknowledgement
3. patient identification and body-area selection
4. lesion labeling and pre-scan questionnaire
5. image capture from camera or gallery
6. guided 2-second stabilization for live capture
7. machine learning prediction through the local API
8. ethical presentation of the result
9. upload of images and metadata to Firebase
10. review of saved history and comparison of follow-up entries

The application also includes an educational module with ABCDE guidance, melanoma stage information, FAQs, prevention tips, and a UV guidance feature. These components extend the system from a simple classifier interface into a broader screening-support and follow-up platform.

### 1.9 Resource Requirements

The current implementation uses the following resource stack:

**Hardware Resources**

- Personal computer for development and model training
- Android emulator and Android device for mobile testing
- Local storage for dataset handling and trained model outputs

**Software Resources**

- Flutter and Dart for the mobile frontend
- Firebase Authentication for sign-in and account handling
- Cloud Firestore for scan metadata and history storage
- Firebase Storage for raw and generated lesion image storage
- Python for model training and API serving
- TensorFlow and Keras for machine learning model development
- FastAPI for local prediction API deployment
- HAM10000 dataset for model training and evaluation [8]

### 1.10 Project Scope

**In Scope**

- melanoma risk screening support using a binary machine learning classifier
- patient registration and authentication
- guided mobile image capture and image upload
- storage of scan history and metadata
- longitudinal lesion tracking and comparison
- ethical and non-diagnostic result communication
- follow-up guidance and educational support

**Out of Scope**

- definitive medical diagnosis
- automated treatment recommendation
- replacement of dermatologist assessment or biopsy
- regulated clinical deployment
- fully validated hospital-grade image acquisition hardware

The present implementation is therefore a research prototype and not a certified medical diagnostic system.

---

## Chapter 02: Literature Review

### 2.1 Chapter Overview

This chapter reviews the clinical, technological, and human-centered foundations relevant to the development of the proposed system. It connects melanoma screening practice, patient communication principles, mobile health design, and machine learning-based lesion analysis in order to justify the structure of the implemented application.

### 2.2 Conceptual Basis of the Study

The literature supporting this research can be grouped into four connected domains:

1. melanoma screening and clinical assessment
2. patient communication and psychological safety
3. machine learning for skin lesion analysis
4. user-centered mobile health system design

These four domains collectively shape the design of the SkinSafe prototype. The clinical domain explains what suspicious lesions look like and why early escalation matters. The communication domain explains how digital systems should avoid harmful wording. The machine learning domain justifies the use of image classification models. The mobile health design domain supports the need for practical, understandable, and ethically framed workflows.

### 2.3 Clinical and Psychological Context

Melanoma assessment often begins with visual inspection using the ABCDE criteria: asymmetry, border irregularity, color variation, diameter, and evolving change [1]. Dermoscopy improves specialist inspection, while biopsy remains the final diagnostic standard [2]. Although these clinical principles are well established, patients outside specialist settings frequently rely on their own interpretation of visible lesions. This can lead either to harmful delay or to anxiety caused by uncertainty.

The communication of serious health concerns must therefore be handled carefully. Protocols such as SPIKES demonstrate that distressing medical information should be communicated with structure, empathy, and actionable next steps [3], [4]. While these principles are usually discussed in clinician-patient communication, they are also relevant in digital health interfaces. A screening application should not present its output as a final diagnosis, especially when the input image quality and the model context may vary.

### 2.4 Existing Systems and Gaps

Existing skin-related mobile applications often prioritize prediction output but underemphasize usability, longitudinal tracking, and emotional safety [6], [11]. Many solutions present results with excessive certainty or without providing clear follow-up actions. This is problematic in the context of health anxiety and self-screening behavior.

Another important limitation in existing systems is the inconsistency of follow-up imaging. If images are captured under different angles, distances, lighting conditions, and framing, then comparing lesion change over time becomes unreliable. This reduces the usefulness of image-based self-monitoring and weakens machine learning interpretation in real-world settings.

Therefore, the literature suggests a clear design gap: there is a need for a mobile system that combines guided image capture, ethically framed result communication, structured follow-up management, and practical patient history storage rather than focusing only on isolated image classification.

### 2.5 Machine Learning and Mobile Health Design

Deep learning has significantly improved image-based analysis in medical domains [7], [10]. Skin lesion classification studies using large image archives demonstrate the potential of convolutional neural networks to recognize suspicious patterns [7], [8], [9]. However, the practical value of such models depends on data quality, correct framing of the results, and realistic deployment limitations.

In this project, the machine learning pipeline is intentionally framed as **screening support**. The dataset used for training is HAM10000, which is valuable for experimental model development [8], but it is largely composed of dermoscopic images rather than ordinary smartphone photographs. This creates an important boundary between model evaluation performance and real-world generalization. Therefore, responsible mobile design requires that the app communicate recommendations in supportive terms such as "Low melanoma risk", "Caution advised", and "Specialist review recommended" rather than issuing a definitive diagnosis.

User-centered design research in mobile health further supports the need for interfaces that are understandable, calm, and action-oriented [11], [12]. This principle directly influences the current application design, which includes educational support, safety disclaimers, and follow-up planning rather than only a raw risk score.

### 2.6 Research Gap Justification

The literature review indicates that prior work often treats machine learning accuracy, mobile UX, and medical communication as separate concerns. This project addresses the gap by integrating them within a single software artifact. The implemented prototype attempts to contribute in three ways:

1. it translates machine learning output into ethical, user-friendly screening support
2. it supports lesion follow-up through structured history and comparison
3. it frames mobile screening as a bridge to clinical review rather than as a replacement for professional diagnosis

This combined approach justifies the development of the SkinSafe system as both a software engineering artifact and a clinically cautious mobile health prototype.

---

## Chapter 03: Methodology

### 3.1 Research Paradigm

This study follows the **Design Science Research (DSR)** paradigm because the central activity of the research is the design, implementation, and evaluation of a software artifact created to address a real-world healthcare accessibility problem. The artifact is not only theoretical; it is a functioning mobile application and machine learning pipeline intended to demonstrate practical utility.

### 3.2 Research Approach

The study adopts a pragmatic approach. It combines theoretical understanding from melanoma screening literature and patient communication practice with practical software engineering and machine learning implementation. This approach is suitable because the research aims to produce a usable system while also reflecting on the quality, boundaries, and limitations of that system.

### 3.3 Research Strategy

The strategy used in this project combines:

- artifact construction through iterative software development
- model development and evaluation through supervised learning
- functional verification of the application workflow
- reflective analysis of the implemented prototype

At the current interim stage, the work is focused more strongly on implementation completion and technical validation than on large-scale human subject evaluation. Therefore, the present report includes system results and discussion, while broader user evaluation remains a later-stage activity.

### 3.4 Data Collection and Technical Inputs

The machine learning component uses the HAM10000 skin lesion dataset as the main secondary data source [8]. Metadata entries are mapped to corresponding lesion images, and the classification task is simplified into a binary problem:

- `mel` mapped to `melanoma`
- all other diagnoses mapped to `non_melanoma`

This decision was made to align the ML output with the current application objective of risk-oriented screening support rather than complex multi-class diagnosis.

For application development, technical inputs include:

- mobile interface requirements derived from the project objectives
- longitudinal tracking requirements for lesion follow-up
- ethical wording requirements derived from clinical communication literature
- cloud storage requirements for account data, images, and scan history

### 3.5 Methodology Execution Workflow

The methodology was executed through the following phases:

1. **Problem Analysis**  
   The initial phase examined the gap between lesion appearance and clinical action, as well as weaknesses in existing mobile screening tools.

2. **Requirement Refinement**  
   Based on ongoing review and supervisor guidance, the system direction was refined from a broad conceptual proposal into a realistic screening-support application with clearly bounded diagnostic claims.

3. **Machine Learning Pipeline Development**  
   A Python-based training pipeline was built to process HAM10000 metadata and images, split the dataset into training, validation, and test subsets, and train a binary classifier using transfer learning.

4. **Mobile Application Development**  
   A Flutter frontend was implemented to support authentication, onboarding, medical safety acknowledgement, guided scanning, result presentation, and educational content.

5. **Cloud Integration**  
   Firebase Authentication, Cloud Firestore, and Firebase Storage were integrated for account management, structured scan records, and lesion image storage.

6. **Tracking and Follow-Up Features**  
   Lesion labeling, patient history, comparison logic, ghost-reference guidance, and follow-up scheduling support were added to strengthen longitudinal self-monitoring.

7. **Evaluation and Reflection**  
   Model metrics, functional flow completion, and prototype limitations were analyzed to produce the current interim results and discussion.

### 3.6 Model Development Procedure

The current machine learning model was trained using a transfer learning workflow built around MobileNetV2. Images were resized to `224 x 224`, and data augmentation was applied through random horizontal flipping, slight rotation, zoom, and contrast variation. The training script uses class weighting to address class imbalance and evaluates the model using accuracy, AUC, precision, and recall. Early stopping, checkpointing, and learning-rate reduction were used to improve training stability.

The dataset was divided into training, validation, and test subsets using stratified splitting, with validation and test ratios set to `0.15` each. The final outputs include the trained Keras model, a TensorFlow Lite export, model configuration metadata, and evaluation metrics files. The deployed mobile workflow currently uses the local Python prediction API for inference, while the TensorFlow Lite export remains available for future on-device inference work.

### 3.7 Application Architecture

The implemented system uses a layered architecture with the following major components:

- **Flutter frontend:** user interface, scan flow, educational screens, and history views
- **Prediction service:** local HTTP request to the FastAPI melanoma prediction endpoint
- **Firebase Authentication:** sign-up, sign-in, password reset, and session handling
- **Cloud Firestore:** storage of structured scan records and patient-linked history
- **Firebase Storage:** storage of raw scan images and generated lesion illustrations
- **Follow-up services:** lesion comparison, history grouping, and next-review planning
- **UV guidance service:** contextual prevention support using current or fallback UV data

This architecture was selected because it separates the mobile interaction layer from the prediction layer while preserving the ability to evolve the ML component independently of the user interface.

### 3.8 Project Management Methodology

The project follows an Agile development style informed by SCRUM principles [13]. Iterative implementation allowed gradual improvement of the application after reviews and technical testing. Instead of attempting to finalize all functionality at once, the system evolved through practical milestones:

- authentication and onboarding
- scan capture workflow
- result generation and storage
- history and comparison support
- learning and prevention content
- refinement of safety-focused wording

This approach was appropriate because both UI requirements and machine learning integration benefited from incremental refinement.

### 3.9 Timeline Status

The original project timeline spans approximately November 2025 to November 2026. As of **August 10, 2026**, the project has reached the implementation and interim evaluation stage.

| Phase | Planned Focus | Current Status |
|---|---|---|
| Months 1-2 | Proposal and literature review | Completed |
| Months 3-5 | Dataset preparation and model experimentation | Completed |
| Months 6-8 | Mobile app implementation and feature integration | Largely completed |
| Months 9-10 | Extended evaluation and refinement | In progress |
| Months 11-12 | Final write-up and defense preparation | Pending |

### 3.10 Ethical Considerations

Ethical boundaries remain central to this project. The application is explicitly designed as a screening-support tool and not as a diagnostic authority. The interface avoids statements that imply medical certainty and instead uses cautious categories such as "Low melanoma risk", "Caution advised", and "Specialist review recommended". A one-time medical safety acknowledgement is included before signed-in use, and the application emphasizes that concerning lesions require professional review.

The system also stores personal scan history and images; therefore, privacy and data handling considerations are important. Firebase services are used to structure and store data for research prototype purposes, and the application presents privacy and safety information to users. Despite these efforts, the current system should still be treated as an academic prototype rather than a production-grade clinical platform.

---

## Chapter 04: Results and Discussion

### 4.1 Chapter Overview

This chapter presents the current implementation status of the project and discusses the observed technical results. Since the application is already built as a working prototype, this section focuses on delivered software features, machine learning evaluation metrics, and the strengths and limitations of the current version.

### 4.2 Development Progress Summary

The first interim submission described the intended artifact at a conceptual level. The second interim demonstrates that the core application has now been implemented as an integrated prototype. The current project status can be summarized as follows.

| Component | Current Status | Notes |
|---|---|---|
| Flutter frontend | Implemented | Includes login, onboarding, scan, history, learn, dashboard, and profile flows |
| Firebase Authentication | Implemented | Email/password sign-up, login, password reset, and logout |
| Medical safety acknowledgement | Implemented | One-time warning before signed-in use |
| Guided scan workflow | Implemented | Patient selection, lesion labeling, questionnaire, capture, analysis, save |
| Camera and gallery input | Implemented | User can capture or upload a lesion image |
| 2-second stability guidance | Implemented | Guided hold for live camera capture |
| Ghost-reference support | Implemented | Supports more consistent follow-up alignment |
| Machine learning prediction API | Implemented | Local FastAPI endpoint connected to mobile app |
| Firebase Storage image upload | Implemented | Raw and generated images can be stored |
| Firestore scan history | Implemented | Metadata and longitudinal history are saved |
| Lesion comparison | Implemented | Latest and previous follow-up entries can be compared |
| Follow-up planning | Implemented | Next review timing is derived from saved risk context |
| Educational module | Implemented | ABCDE guide, FAQ, stages, and prevention tips |
| UV guidance | Implemented | Current or fallback UV support included |
| Doctor directory | Partially addressed | Current system provides follow-up guidance rather than a full live directory |
| Full clinical validation | Not completed | Remains outside the present interim scope |

### 4.3 Machine Learning Results

The current model evaluation outputs from the held-out test set are shown below.

| Metric | Value |
|---|---:|
| Accuracy | 0.6687 |
| AUC | 0.7968 |
| Precision | 0.2291 |
| Recall | 0.8383 |
| Loss | 0.6531 |

These results indicate that the model is relatively strong at identifying potentially suspicious melanoma-like patterns in terms of recall, but it also has limited precision. This means the model is better suited to screening support than to high-confidence diagnosis. In practical terms, the current classifier is more acceptable as a tool for encouraging caution and follow-up than as a system for confirming disease presence.

The training history also shows promising validation behavior, including validation accuracy near `0.6880` and validation AUC near `0.8495`, suggesting that the model learned useful discriminatory patterns from the dataset. However, these values must still be interpreted carefully because the evaluation remains dataset-based and not clinically validated in a real-world deployment context.

### 4.4 Discussion of the Implemented System

One of the major strengths of the current application is that it no longer treats prediction as an isolated output. Instead, the system integrates prediction with workflow structure. Before analysis, the user records patient information, identifies body area and lesion location, and answers a short questionnaire. After analysis, the app stores history, provides comparison support, and presents follow-up-oriented messaging. This significantly improves the practical value of the application relative to a basic image classifier.

Another strength is the use of ethical communication. The application avoids direct diagnostic claims and instead presents graded guidance. This design choice is important because even a technically competent model can cause harm if its outputs are communicated without caution. By framing results as screening support and directing users toward clinician review when needed, the system aligns better with the intended educational and supportive role of the application.

The tracking features are also important. History grouping by patient, body area, and lesion label creates a more meaningful longitudinal record. The inclusion of ghost-reference guidance, comparison logic, and follow-up scheduling reflects the practical reality that lesion change over time is clinically meaningful. This is one of the main areas where the current system moves beyond a static detection concept.

At the same time, the results reveal important limitations. The machine learning model is trained on HAM10000, which is primarily a dermoscopic dataset. The mobile application, however, can accept ordinary camera images. This creates a domain mismatch between the training distribution and real-world smartphone usage. Therefore, while the current model metrics are acceptable for an academic prototype, they should not be interpreted as evidence of clinical readiness.

Precision is another limitation. A precision value of `0.2291` means the model may produce a considerable number of false positives when identifying melanoma-like patterns. In a screening-support context this is less dangerous than false negatives, but it still reinforces the need for cautious wording and professional review rather than self-diagnosis.

### 4.5 Current Limitations and Remaining Work

The present system should be understood as a substantial prototype rather than a complete final product. The following items remain important limitations or next-stage tasks:

1. large-scale usability testing has not yet been completed
2. formal psychological impact evaluation has not yet been completed
3. the current inference flow depends on a local API rather than a fully deployed production backend
4. the machine learning pipeline has not yet been clinically validated against smartphone-acquired ground-truth data
5. the app provides clinician guidance but not yet a fully integrated live dermatologist directory
6. the current model is binary and does not yet support broader lesion categorization

### 4.6 Interim 2 Summary

This second interim demonstrates clear progress from proposal to implementation. The project now includes a functioning mobile application, an integrated machine learning prediction workflow, lesion history and comparison support, ethical result communication, and measurable model outputs. The current state of the research therefore supports the conclusion that the project has moved beyond conceptual design and into a valid prototype stage suitable for further evaluation, refinement, and final dissertation development.

---

## References

[1] D. S. Rigel, R. J. Friedman, A. W. Kopf, and D. Polsky, "ABCDE - an evolving concept in the early detection of melanoma," *Archives of Dermatology*, vol. 141, no. 8, pp. 1032-1034, 2005.

[2] M. E. Vestergaard, P. Macaskill, P. E. Holt, and S. W. Menzies, "Dermoscopy compared with naked eye examination for the diagnosis of primary melanoma," *British Journal of Dermatology*, vol. 159, no. 3, pp. 669-676, 2008.

[3] W. F. Baile, R. Buckman, R. Lenzi, G. Glober, E. A. Beale, and A. P. Kudelka, "SPIKES - A six-step protocol for delivering bad news: application to the patient with cancer," *The Oncologist*, vol. 5, no. 4, pp. 302-311, 2000.

[4] L. Fallowfield and V. Jenkins, "Communicating sad, bad, and difficult news in medicine," *The Lancet*, vol. 363, no. 9405, pp. 312-319, 2004.

[5] L. G. Gordon and D. Rowell, "Health system costs of skin cancer and cost-effectiveness of skin cancer prevention and screening," *European Journal of Cancer Prevention*, vol. 24, no. 2, pp. 141-149, 2015.

[6] D. Lupton, "Apps as artefacts: Towards a critical perspective on mobile health and medical apps," *Societies*, vol. 4, no. 4, pp. 606-622, 2014.

[7] A. Esteva et al., "Dermatologist-level classification of skin cancer with deep neural networks," *Nature*, vol. 542, no. 7639, pp. 115-118, 2017.

[8] P. Tschandl, C. Rosendahl, and H. Kittler, "The HAM10000 dataset, a large collection of multi-source dermatoscopic images of common pigmented skin lesions," *Scientific Data*, vol. 5, no. 1, p. 180161, 2018.

[9] N. C. F. Codella et al., "Skin Lesion Analysis Toward Melanoma Detection: A Challenge at the 2017 International Symposium on Biomedical Imaging (ISBI)," *IEEE ISBI*, pp. 168-172, 2018.

[10] M. A. Mazurowski, M. Buda, A. Saha, and M. R. Bashir, "Deep learning in medical imaging: The state of the art," *International Journal of Computer Assisted Radiology and Surgery*, vol. 14, no. 1, pp. 1449-1463, 2019.

[11] C. R. McCurdie et al., "mHealth consumer apps: The case for user-centered design," *Biomedical Instrumentation and Technology*, vol. 46, no. s2, pp. 49-56, 2012.

[12] L. L. E. et al., "Evaluation of mobile health applications: A systematic review," *Journal of Medical Internet Research*, vol. 17, no. 12, p. e290, 2015.

[13] K. Schwaber and J. Sutherland, "The Scrum Guide," Scrum Alliance, 2020.

[14] World Health Organization, "Global action plan for the prevention and control of noncommunicable diseases 2013-2020," Geneva, Switzerland, 2013.
