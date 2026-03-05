# GestureModel Training Backend Comparison

This document compares three viable on-device training approaches for the `GestureModelModule` on iOS,
following the discovery that `MLActivityClassifier` (originally planned) is macOS-only.

---

## Context and Constraints

- Deployment target: **iOS 16.0** (current across all pods and the Podfile)
- Input data: `HandFilm` → 60 frames × 126 features/frame (normalized landmarks + velocity), already
  produced by `FeaturePreprocessor`
- Goal: train a multi-class gesture classifier **on-device** in `ModelTrainingApp` and use it for
  inference in `HandGestureRecognizingFramework`
- `MLActivityClassifier` is **not available on iOS** — confirmed absent from the iOS
  `CreateML.framework` Swift interface

---

## Option B — Create ML Tabular Classifiers (iOS-native)

### What it is

Use `MLBoostedTreeClassifier` or `MLRandomForestClassifier` from `CreateML.framework`, which **are**
present in the iOS SDK since iOS 15.0. Training takes a flat `TabularData.DataFrame` — one row per
`TrainingExample`, with aggregated per-film summary statistics as columns.

### How it works

Because tabular classifiers take a single flat row (not a time sequence), the 60-frame sequence must
be compressed into a fixed-size feature vector per film:

- **Statistical summaries per landmark dimension**: mean, std, min, max of each of the 63 normalized
  coordinates and 63 velocity values across all 60 frames → `63 × 4 + 63 × 4 = 504 features`
- Or a simpler subset: mean + std per landmark dimension → `63 × 2 + 63 × 2 = 252 features`
- Label column: `gestureId` string

Training, compiling to `.mlmodel`, and saving are all available on iOS 15+. No minimum version
bump required from iOS 16.0.

### Inference

Load the trained `.mlmodel` with `MLModel`, construct an `MLDictionaryFeatureProvider` with the
same summary features from the incoming `HandFilm`, call `model.prediction()` — same as the
current plan.

### Accuracy considerations

| Gesture type | Tabular classifier suitability |
|---|---|
| Static shapes (`openHand`, `closedFist`, `thumbsUp`, `peace`, `pointing`) | **Good** — captured by mean landmark positions |
| Dynamic motion (`swipeLeft`, `swipeRight`, `wave`, `grab`) | **Weaker** — temporal order lost; directional swipes may blur together |

Adding motion-specific summary features (net displacement of wrist, dominant axis of movement) helps,
but the classifier still cannot learn sequential patterns.

### Training time on device

Boosted trees and random forests on ~200 examples with ~252 features: **< 5 seconds** on any modern
iPhone. No GPU needed.

### Changes to current implementation

- Replace `CreateMLAdapter.swift` entirely: no CSV files, no `labeledDirectories`, no
  `MLActivityClassifier`
- Add a `StatisticalFeatureExtractor` that collapses a `HandFilm` into a flat `[Double]` summary
  vector
- `FeaturePreprocessor` remains useful for inference path (TFLite) but the training path uses the
  summarised form
- `predictWithCoreML` uses the same summarised feature vector at inference time

### Minimum iOS version

**iOS 15.0** — but since the project already targets iOS 16.0, **no change needed**.

---

## Option C — TensorFlow Lite (LiteRT) Inference + External Training

### What it is

Train a model externally — in Python with Keras/scikit-learn — export it to `.tflite` format, bundle
it in the app or store it in Documents, and run **inference only** on-device using the already-linked
`TensorFlowLiteSwift 2.13.0` pod. `ModelTrainingApp` exports the labelled dataset as JSON for
offline training; the user imports the resulting `.tflite` back into the app.

### How it works

#### Training (off-device, Python)

```
HandFilm dataset (exported JSON)
  → Python: load, preprocess (same 60×126 matrix or summary features)
  → Keras LSTM or sklearn RandomForestClassifier
  → coremltools or tf.lite.TFLiteConverter → .tflite / .mlmodel
  → Copy to device Documents or bundle in app
```

**Scikit-learn note**: sklearn itself has no iOS port, but a trained sklearn model can be:
1. Converted to CoreML via `coremltools.converters.sklearn.convert()` → `.mlmodel`
2. Converted to ONNX via `sklearn-onnx` → ONNX → TFLite (roundabout)
3. Saved and re-implemented: sklearn Random Forest predictions are mathematically simple enough to
   re-implement in Swift at inference time (each tree is a series of threshold comparisons), though
   this is non-trivial to maintain.

The cleanest path is: train sklearn or Keras on macOS/Python → export to `.mlmodel` via `coremltools`
→ load with `MLModel` on iOS. The `TensorFlowLiteSwift` pod is only needed if the `.tflite` path is
preferred.

#### On-device training

LiteRT **does support on-device training** (via the model personalization API with `train`,
`infer`, `save`, `restore` signatures), but this is **documented for Android only** as of 2024–2025.
The iOS Swift SDK (`TensorFlowLiteSwift`) exposes only an `Interpreter` for inference; there is no
Swift API for the training signatures. On-device training with TFLite on iOS is effectively
**not supported**.

### Accuracy considerations

| Model choice | Accuracy |
|---|---|
| Keras LSTM trained in Python | **Best possible** — captures full temporal sequence |
| Keras 1D-CNN trained in Python | Very good — efficient, fast inference |
| sklearn RandomForestClassifier | Good — same as Option B but trained with more examples |

### Inference

Use the existing `TensorFlowLiteSwift` `Interpreter` API: copy feature matrix into input tensor,
invoke, read output probabilities. The 60×126 matrix from `FeaturePreprocessor` is directly usable
as-is — no summary aggregation needed for LSTM/CNN models.

### Changes to current implementation

- `CreateMLAdapter.swift`: can be removed or repurposed as a data export helper
- `GestureModel.trainWithTensorFlow`: changes to a data-export function only, not a real training call
- `predictWithTensorFlow`: implement with real `Interpreter` calls (this was already stubbed)
- `ModelTrainingApp`: add a dataset export button (JSON) and a model import flow (file picker for
  `.tflite` or `.mlmodel`)
- A Python training script lives outside the iOS project (e.g. in `scripts/` or `python/`)

### Minimum iOS version

**No change** — `TensorFlowLiteSwift` supports iOS 12+. Project stays at iOS 16.0.

---

## Summary Comparison

| Criterion | B — Create ML Tabular | C — TFLite + External Training |
|---|---|---|
| **On-device training** | Yes, fully on-device | No — training is off-device (Python) |
| **iOS version required** | iOS 15+ (project already on 16) | iOS 12+ |
| **Architecture change** | Small — replace `CreateMLAdapter`, add stat features | Medium — add export UI, import flow, Python script |
| **Temporal sequence learning** | No — sequence collapsed to statistics | Yes (LSTM/CNN) or No (sklearn RF) |
| **Expected accuracy (static gestures)** | Good | Good–Excellent |
| **Expected accuracy (dynamic gestures)** | Moderate (depends on motion features) | Excellent (LSTM) |
| **Training speed on device** | < 5 seconds | N/A (off-device) |
| **Dependencies added** | None (CreateML already in iOS SDK) | None new (TFLiteSwift already linked) |
| **User experience** | Train directly in the app | Export data → train on Mac → import model |
| **Scikit-learn usable?** | No (no iOS port) | Yes, via coremltools export on macOS |
| **Inference path changes** | Moderate (summary features replace sequence) | Small (enable existing TFLite stub) |
| **Retraining in app** | Yes — user collects data and taps Train | No — requires going through Python |

---

## Recommendation

**Option B** is recommended as the **primary backend** for the current phase:

- Fully on-device, no external tooling required for the user
- Works today with zero new dependencies
- Sufficient accuracy for the 10-gesture set when paired with good motion summary features
  (add net wrist displacement and dominant motion axis to distinguish swipe directions)
- Consistent with the plan's goal of training in `ModelTrainingApp`

**Option C** (TFLite with Python training) is the natural **upgrade path** once accuracy needs
increase: the existing `TensorFlowLiteSwift` stub becomes real inference, and the Python script
can use an LSTM trained on exported datasets. The two backends coexist in the current
`BackendType` enum.

### Minimum version impact

**Neither option requires a version bump.** Both work on iOS 15+; the project already targets
iOS 16.0.

---

## Required changes to the existing implementation

The current code has `CreateMLAdapter.swift` built around `MLActivityClassifier`. The changes needed
for Option B:

1. **Replace `CreateMLAdapter.swift`** — rewrite to use `MLBoostedTreeClassifier` with a
   `TabularData.DataFrame`. The CSV/`labeledDirectories` approach is dropped.
2. **Add `StatisticalFeatureExtractor.swift`** — collapses `HandFilm` → `[Double]` summary vector
   (mean, std per landmark/velocity dimension + motion-specific features).
3. **Update `predictWithCoreML`** in `GestureModel.swift` — use summary features instead of the
   60×126 matrix for inference.
4. **`FeaturePreprocessor.swift`** — keep as-is; useful if/when TFLite inference is enabled.
5. **No changes** to `TrainingView`, `ModelTrainingApp`, DTOs, or `GestureModelError`.
