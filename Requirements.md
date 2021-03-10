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

### Attitude Condition Period Use Case

#### Data:
- Attitude
    
#### Primary course (happy path):
1. Before the period starts, system checks for Motion Client for any errors.
2. System starts the period.
3. At the first time interval, system recieves the first attitude, records it, and generates valid target attitude different from the first attitude.
3. At each time interval, system recieves, stores the record and the time, and reports the current progress to the target position.
4. System stops the period and upon returns the percentage of attitudes that were within the threshold.

#### Check Error Course (sad path)
1. System delivers error.

#### Start Updates Error Course (sad path)
1. System stops the condition period.
2. System delivers error.

#### Stop Updates Error Course (sad path)
1. System delivers warning that condition period was already stopped.

---

### Intervention Session with Attitude Condition Use Case

#### Data:
- Current Period Progress
- Progress Above Threshold for a Period

#### Primary course (happy path)
1. System records session start time.
2. System uses the Attitude Condition Period Use Case.
3. During the updates after start, System takes current period progress and determines how much to change the view alpha based on intervention policy.
4. System stops period and changes view alpha based on intervention policy end period alpha.
5. System records progress towards threshold along with data from the view controller for each period.
6. System starts new period.
8. When app disappears or user ends session manually, system sends session data to Session Store.


#### Attitude Condition Period Start Error (Sad Path)

1. System stops the condition period if it is a start error.
2. System delivers error as a critical toast/notification.

#### Attitude Condition Period Stop Error (Sad Path)
1. System delivers error as a warning toast/notification.
