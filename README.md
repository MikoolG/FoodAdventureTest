# Food Truck Adventure

## Setup:
- **Ruby version:** `3.2.0`
- **Rails:** `7`
- Ensure you run and pass all spec tests.
- **Note:** You will need to set up your own Twilio credentials.

## UI:
- UI uses **Tailwind** for styling.
- **Color Codes:**
  - **Blue:** `#00CAE3`
  - **Pink:** `#FF7F96`
  - **Gray:** `#CDDCE8`

## Data:
- An import worker runs every 7 days.
- Data is read from this CSV link: [Mobile-Food-Facility-Permit](https://data.sfgov.org/Economy-and-Community/Mobile-Food-Facility-Permit/rqzj-sfat/data)

## Functionality:

### 1. Personalized Food Truck Adventure:
- **User Input:**
  - **Food Preferences:** Users can select from a list of available cuisines or specific dishes. A dropdown menu is available for ease of selection.
  - **Number of Trucks:** Users specify how many food trucks they wish to visit.
  - **Adventure Duration:** Users set their food truck adventure's preferred start and end times.

### 2. Adventure Initialization:
- The system selects available food trucks based on their operational hours and locations.
- Computes an optimal route.
- Sends a message at the start time: "Ready for a culinary journey? Head over to [First Truck Name] at [Location]. Bon appétit!"

### 3. Interactive Messaging System:
- On arriving at a truck, users send an "arrived" message.
- The system replies with personalized messages about the food truck and location.
- This continues for each truck on the list.

### 4. Emergency Stop:
- Users can send a "stop" message at any point to end the adventure.
- Upon receiving this, the system sends a concluding message.

### 5. Safety Measures:
- The texting system is designed with user privacy in mind.
- **Twilio** is the third-party vendor in use.
- User's phone number is deleted after the adventure concludes.

### 6. Adventure Conclusion:
- After all specified trucks are visited or when the adventure end time is reached, the system sends a conclusion message.

## Async Processing:
- Uses **Sidekiq** for asynchronous processing.

## Desired Improvements:
- The current order of food trucks in the adventure uses a basic approximation algorithm. A better algorithm with user-inputted locations for optimal routing would be beneficial.
- It currently uses the zip code and the haversine formula to determine distance.
- Expansion of data sources to include other cities is needed; currently, only San Francisco is supported.
- An expiration system for adventures that aren't updated within 24 hours is suggested.
- After the adventure, users can rate or provide feedback.
- Periodic user engagement initiatives can be introduced for retaining user interest.
