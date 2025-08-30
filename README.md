# BinBuddy

BinBuddy is a project with a **Ballerina backend** .  

The backend provides API services, and the frontend interacts with these APIs.

---

## Project Structure

    repo-root/
         ├── BinBuddy/ # Ballerina backend
         └── frontend/ 
  
---

## Prerequisites

Make sure you have installed:

- [Ballerina](https://ballerina.io/download/)
- Git

---

## Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/<your-username>/<your-repo>.git
cd <your-repo>
```
### 2. Run the Backend (Ballerina)

```bash
cd BinBuddy
bal run
```
The Ballerina service will run on http://localhost:8080.

  Example API endpoint:
  
  - http://localhost:8080/hello/greeting

### 3. Run the Frontend 
- open FrontEnd/index.html

Open it in your browser and click buttons to call the backend APIs.

---
### Development Notes

 - Ballerina backend folder: BinBuddy/

 - React frontend folder: frontend/

 - Ensure CORS is configured in Ballerina if accessing APIs from a different port.

 - Add new API endpoints in BinBuddy/src and update frontend accordingly.


