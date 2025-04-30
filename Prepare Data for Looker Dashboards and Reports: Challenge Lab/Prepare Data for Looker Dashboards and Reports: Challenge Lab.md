### Prepare Data for Looker Dashboards and Reports: Challenge Lab

---


### ⚠️ Disclaimer
- **This script and guide are provided for  the educational purposes to help you understand the lab services and boost your career. Before using the script, please open and review it to familiarize yourself with Google Cloud services. Ensure that you follow 'Qwiklabs' terms of service and YouTube’s community guidelines. The goal is to enhance your learning experience, not to bypass it.**

### ©Credit
- **DM for credit or removal request (no copyright intended) ©All rights and credits for the original content belong to Google Cloud [Google Cloud Skill Boost website](https://www.cloudskillsboost.google/)** 🙏

---
# Looks for Each Task

Look 1:-

```
explore: +airports {
     query: start_from_here{
      dimensions: [city, state]
      measures: [count]
      filters: [airports.facility_type: "HELIPORT^ ^ ^ ^ ^ ^ ^ "]
    } 
}

```

Look 2:-

```
explore: +airports {
    query: start_from_here{
      dimensions: [facility_type, state]
      measures: [count]
    }
  }


```

Look 3:-

```
explore: +flights {
    query: start_from_here{
      dimensions: [aircraft_origin.city, aircraft_origin.state]
      measures: [cancelled_count, count]
    }
}

```


## Join the Community

[![Telegram](https://img.shields.io/badge/Join-Telegram_Group-blue?style=for-the-badge&logo=telegram)](https://t.me/+gBcgRTlZLyM4OGI1) - Connect with fellow cloud enthusiasts, ask questions, and share your learning journey.
