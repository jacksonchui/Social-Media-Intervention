#  Requirements for HCI Mobile Embodied Social Media Interventions

## Attitude Condition Feature Specs

### Story: Online research subject browses social media with Attitude Intervention

### Narrative #1

```
As a online subject
I want the app every x minutes 
And give me a new target attiude to adjust to
And adjust the brightness depending on how close I am to a new attitude
So that I am forced to adjust to a new scenario
```

#### Scenarios (Acceptance Criteria)

```
Given there are no condition periods
 When the app starts
 Then the condition service starts the motion updates

Given the first motion update on a condition period
 When the motion update returns a result
 Then the app records the start attitude.
  And randomly generates a new target attitude.

Given the condition period is in-progress
 When the subject moves their iPhone
 Then the app should adjust the view alpha
Based on how close they are to the target attitude

Given the current period is completed
  And the subject has reached a threshold for at least X% of the time
 Then show the subject a toast that the target attitude is changing
  And log the result of the period in the current session
  And the app should restart the condition service
```

## Use Cases

### Attitude Condition Use Case

#### Data:
- CMDeviceMotion
    
#### Primary course (happy path):
1. `CMDeviceMotionUpdates` are started.
2. System saves the initial pitch/yaw/roll.
3. System generates a new position.
4. System compares pitch/roll/yaw relative to desired position and delivers progress as a float.
5. System notifies delegate of the progress.
6. System repeats, checking for when the condition period is completed.
