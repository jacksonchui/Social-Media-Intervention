#  Requirements for HCI Mobile Embodied Social Media Interventions

## Angle Condition Feature Specs

### Story: Online research subject browses social media with Angle Intervention

### Narrative #1

```
As a online subject
I want the app every x minutes 
- give me a new target position to move to
- adjust the brightness depending on how close I am to a new angle
So that I am forced to adjust too a new scenario
```

#### Scenarios (Acceptance Criteria)

```
Given the condition period is in-progress
 When the subject moves their iPhone
 Then the app should adjust the view alpha
Based on the condition threshold and a polynomial step function

Given the condition period is completed
  And the subject has reached a threshold for at least X% of the time
 Then the app should alert the subject that the angle is changing
  And log the result
  And generate a new angle condition relative to the subject's current angle
  And reset the timer
```

## Use Cases

### Angle Condition Use Case

#### Data:
- CMDeviceMotion
    
#### Primary course (happy path):
1. `CMDeviceMotionUpdates` are started.
2. System saves the initial pitch/yaw/roll.
3. System generates a new position.
4. System compares pitch/roll/yaw relative to desired position and delivers progress as a float.
5. System notifies delegate of the progress.
6. System repeats, checking for when the condition period is completed.
