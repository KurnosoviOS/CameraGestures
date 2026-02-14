# CameraGestures - Dynamic Gesture Recognition System

## Project Overview

CameraGestures is a modular dynamic gesture recognition system that captures hand movements through a camera and translates them into recognizable gestures for application control. The system leverages MediaPipe Hands for real-time hand tracking and supports multiple machine learning backends for gesture classification.

The project is designed with modularity and interchangeability in mind, allowing different neural network implementations while maintaining consistent APIs across modules. This architecture enables easy experimentation with different ML approaches and seamless integration into various applications.

## Design Principles

- **Modularity**: Each module has a single, well-defined responsibility with clear interfaces
- **Interoperability**: Consistent APIs enable seamless integration between modules
- **Extensibility**: New gesture types and ML backends can be added without modifying core architecture
- **Performance**: Real-time processing optimized for <500ms latency requirement
- **Testability**: Independent module testing and validation capabilities
- **Flexibility**: Support for different deployment scenarios from development to production

## System Architecture

The system consists of four interconnected modules that work together to provide end-to-end gesture recognition:

```
Camera Input → HandsRecognizing → GestureModel → Application Output
                     ↓               ↓
                Training Data → ModelTraining
```

## Module Descriptions

### 1. HandsRecognizing Module
**Purpose**: Real-time hand detection and coordinate extraction from camera input.

**Responsibilities**:
- Capture video frames from camera
- Detect and track hand landmarks using MediaPipe Hands
- Extract 21-keypoint hand skeleton coordinates
- Generate timestamped sequences of hand positions
- Output structured handshot and handfilm data

**Technology**: MediaPipe Hands (Google)
**Implementation Language**: C++
**Platform Support**: Cross-platform (Windows, macOS, iOS, Android)

### 2. GestureModel Module
**Purpose**: Neural network abstraction layer for gesture classification.

**Responsibilities**:
- Provide unified API for different ML backends
- Accept handfilm sequences as input
- Output gesture predictions with confidence scores
- Support model loading/saving operations
- Enable model switching without code changes

**Backend Options** (design-time choice):
- TensorFlow/Keras backend for deep learning approaches
- Scikit-learn backend for traditional ML methods

**Implementation Language**: C++
**Platform Support**: Cross-platform (Windows, macOS, iOS, Android)

### 3. ModelTraining Module
**Purpose**: Training pipeline for gesture recognition models.

**Responsibilities**:
- Collect training data using HandsRecognizing module
- Store handfilm datasets locally
- Train GestureModel instances on collected data
- Provide testing and validation capabilities
- Enable manual correction of predictions
- Support iterative model improvement

**Implementation Language**: Swift (macOS/iOS application)
**Platform Support**: macOS (future), iOS (development)

### 4. HandGestureRecognizing Module
**Purpose**: Production-ready gesture recognition for external applications.

**Responsibilities**:
- Process live camera input through HandsRecognizing
- Generate real-time gesture predictions via GestureModel
- Provide simplified API for application integration
- Limit access to training functionality (read-only model usage)
- Ensure consistent performance and reliability

**Implementation Language**: C++ (exported as binary library)
**Platform Support**: Cross-platform (Windows, macOS, iOS, Android)

## Glossary

### Core Concepts
- **Handshot**: A data structure containing the 21 3D coordinates of hand landmarks captured at a specific moment in time
- **Handfilm**: A time-ordered sequence of handshots with associated timestamps, representing a complete gesture motion
- **Dynamic Gesture**: A hand movement pattern that unfolds over time, requiring temporal analysis for recognition

### Module Names
- **HandsRecognizing**: The computer vision module responsible for hand detection and coordinate extraction
- **GestureModel**: The machine learning abstraction layer that classifies gestures from handfilm data
- **ModelTraining**: The training pipeline module for developing and refining gesture recognition models
- **HandGestureRecognizing**: The production module that provides gesture recognition services to external applications

### Technical Terms
- **Landmark**: Individual coordinate points (x, y, z) representing specific anatomical features of the hand
- **Keypoint**: Synonym for landmark, referring to the 21 tracked points on each hand
- **Temporal Sequence**: Time-ordered data representing how hand positions change over the duration of a gesture
- **Model Backend**: The underlying machine learning framework (TensorFlow/Keras or Scikit-learn)
- **Confidence Score**: Numerical value indicating the model's certainty about a gesture prediction

### Data Structures
- **Coordinate Triplet**: (x, y, z) position data for each hand landmark
- **Timestamp**: Time marker associated with each handshot for temporal analysis
- **Gesture Label**: Classification identifier assigned to recognized gesture patterns
- **Training Dataset**: Collection of labeled handfilms used for model development

