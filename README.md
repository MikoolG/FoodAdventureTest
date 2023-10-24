# Food Truck Adventure
![Food Truck Adventure Home Page](https://github.com/Goeken/FoodAdventure/blob/main/app/assets/images/home-page.png)

## Website Example:

The website is designed to provide an interactive and user-friendly experience for creating personalized food truck adventures. You can navigate the various features, select food preferences, specify adventure details, and interact with the adventure messaging system. Check the website out below:

https://food-truck-adventure-222aa5bc5600.herokuapp.com/ 

**Note:** Currently, the Twilio integration on the website does not have webhooks set up. This means that some real-time messaging features might not be fully operational until webhook integration is complete.

## Setup:
- **Ruby version:** `3.2.0`
- **Rails:** `7`
- Ensure you run and pass all spec tests.
- **Note:** You will need to set up your own Twilio credentials.

## API Keys Setup:
Before running this project, ensure you've set up your own API keys for the following services:

- **Twilio:** Utilized for the adventure messaging functionality. 
- **Google Maps:** Essential for calculating routes and pinpointing truck locations. 

Make sure you have valid API keys and securely integrate them into your environment or your preferred secrets management tool.

## UI:
- UI is powered by **Tailwind** for its styling.
- **Color Codes:**
  - **Blue:** `#00CAE3`
  - **Pink:** `#FF7F96`
  - **Gray:** `#CDDCE8`

## Data:
- An import worker is set to run every 7 days.
- Data is fetched from this CSV link: [Mobile-Food-Facility-Permit](https://data.sfgov.org/Economy-and-Community/Mobile-Food-Facility-Permit/rqzj-sfat/data)

## Functionality:

### 1. Personalized Food Truck Adventure:
- **User Input:**
  - **Food Preferences:** Users can select from a list of cuisines or specific dishes. A dropdown menu is provided for easier selection.
  - **Number of Trucks:** Users decide the number of food trucks they wish to explore.
  - **Adventure Duration:** Users dictate their food truck adventure's start and end times.

### 2. Adventure Initialization:
- The application picks available food trucks by evaluating their operational hours and locations.
- Calculates the most efficient route.
- Dispatches a message at the decided start time: "Ready for a culinary journey? Make your way to [First Truck Name] at [Location]. Bon appétit!"

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
