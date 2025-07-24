# 📬 Clask — Class + Task

Clask is a personal project I built to help students (including me) never miss a test, assignment, or lab again. It connects to your Gmail, tracks emails from your professors, and uses AI to figure out if those emails contain important upcoming tasks. If yes, it adds them straight to a calendar view.

It’s simple, automatic, and built for how school *actually* works.

---

## 💡 Why I built it

As a student, my inbox is chaos—announcements, spam, promo mails, and in between, the one email saying *"Assignment 2 is due next Thursday."*  
I kept missing stuff, and it was stressing me out.

So I built Clask:  
- You tell it which professors’ emails to watch  
- It checks those emails as they arrive  
- If it finds event-worthy info (like deadlines or test dates), it extracts it  
- Then shows it on a calendar

---

## ⚙️ How it works

### Tech Stack

- **Ruby on Rails** — The main framework
- **PostgreSQL** — Data storage
- **Devise + OmniAuth** — For Google login
- **Google Gmail API** — To fetch and track new emails from selected senders
- **Google Pub/Sub** — To receive push notifications for new incoming emails
- **OpenRouter.ai API** — To analyze email content using AI and decide if it contains assignment/test info
- **ActiveJob** — To run background jobs like fetching email history or parsing messages
- **Simple Calendar** — For the calendar UI that shows all upcoming tasks neatly by date

### Flow

1. User logs in with Google
2. Chooses professor emails to track
3. App receives Gmail push notifications
4. If the sender matches, the email is parsed by AI
5. If it's relevant, an Event is created with title, date, and time
6. The event is shown on a calendar

---

## 🔒 Privacy & Data

Clask does **not**:
- Read or store unrelated emails
- Modify your inbox or send any emails
- Sell or share your data with anyone

Clask **only**:
- Reads emails from the senders you specify
- Analyzes email content to extract assignment/test info
- Displays that info to you in a calendar

This app uses the **Gmail API** and the **https://openrouter.ai API**. Please refer to their respective sites for detailed privacy policies and how they handle data.

---

## 🧪 This is a personal project

Clask wasn’t built for a university assignment or company—it’s something I made to solve my own problem.  
Still, I’d love for other students to use it too, or even contribute.

PRs and feedback are welcome ✌️

---

## 📌 Setup (basic)

```bash
# Clone the repo
git clone https://github.com/yourusername/clask.git
cd clask

# Install dependencies
bundle install

# Set up DB
rails db:create
rails db:migrate

# Add your credentials for Gmail + OpenRouter
# Start server
rails server
