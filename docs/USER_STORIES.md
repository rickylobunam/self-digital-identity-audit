# SDIA — User Stories and Acceptance Criteria

> **Format:** `As a [actor], I want [action] so that [benefit]`  
> **Priority:** `P0` = Must Have MVP · `P1` = Should Have MVP · `P2` = v0.2+

---

## Epic 1 — Registration and Access

### US-001 · Audit request registration `P0`
**As** a minor who wants to know what information about me is public,  
**I want** to register my email and nickname in a simple form,  
**so that** I can start the audit process of my digital footprint.

**Acceptance Criteria:**
```gherkin
Scenario: Successful registration
  Given I am on the SDIA home page
  When I enter a valid email (e.g. me@example.com) and a nickname
  And press "Start my audit"
  Then I should see "Check your email! We sent you a validation link"
  And I should receive the validation email in less than 30 seconds
  And the system must create the job without storing my email in plaintext

Scenario: Invalid email
  When I enter "not-an-email" in the email field
  Then I should see an inline error message before submitting
  And no job should be created

Scenario: Empty nickname
  When I leave the nickname field empty
  Then I should see "Nickname is required"
  And the submit button must be disabled

Scenario: Rate limit exceeded
  Given I have already made 3 requests from the same IP in the last hour
  When I try to make a 4th request
  Then I should see "You've reached the hourly limit. Try again in X minutes"
```

---

### US-002 · Email ownership validation `P0`
**As** a minor who received the validation email,  
**I want** to click the link in the email to confirm it is my account,  
**so that** SDIA knows I own the email and I can continue.

**Acceptance Criteria:**
```gherkin
Scenario: Valid and unexpired link
  Given I have an email with the validation link
  When I click the link before it expires (1 hour)
  Then I am redirected to the audit mini-app
  And I see "Email verified! You can now add your accounts"
  And the link is invalidated (cannot be used again)

Scenario: Expired link
  Given the link is more than 1 hour old
  When I click it
  Then I see "This link has expired. Would you like us to send another?"
  And I can request a new link (up to 3 times)

Scenario: Already used link
  Given I already used the link previously
  When someone (or I) tries to use it again
  Then I see "This link has already been used"
```

---

## Epic 2 — Platform Validation

### US-003 · Add an Instagram account `P0`
**As** an authenticated minor in the mini-app,  
**I want** to add my Instagram account to include it in the audit,  
**so that** I can understand what information about me is visible on that network.

**Acceptance Criteria:**
```gherkin
Scenario: Successfully add Instagram
  Given I am in the "My accounts" section
  When I select "Instagram" and type my username "my_user"
  Then I see a step-by-step guide to place the verification code in my bio
  And I see the generated code (e.g. "sdia-4f2a8b") to put in my bio
  And I see a "I placed it, verify!" button

Scenario: Successful verification
  Given I placed the code "sdia-4f2a8b" in my Instagram bio
  When I press "I placed it, verify!"
  Then I see "✅ Instagram verified! You can now remove the code from your bio"
  And the account appears with a green check in my list

Scenario: Verification failed (code not found)
  Given I did NOT place the code in my bio
  When I press "I placed it, verify!"
  Then I see "We couldn't find the code in your bio. Make sure you saved it."
  And I can try again (no retry limit for this scenario)
  And the system does not count this as a penalizable failed attempt

Scenario: Private account
  Given my Instagram account is private
  When the system attempts verification
  Then I see "Your account appears to be private. You need to make it public temporarily to verify."
  And there is a guide on how to make the account public and private again
```

---

### US-004 · Add a Steam account `P0`
**As** a minor gamer,  
**I want** to include my Steam profile in the audit,  
**so that** I understand what information about me is exposed on the platform where I spend the most time.

**Acceptance Criteria:**
```gherkin
Scenario: Public profile
  Given my Steam profile is public
  When I add my Steam username and place the code in "Profile Summary"
  Then the system verifies it successfully

Scenario: Private profile
  When my Steam profile is private
  Then I see a guide to change it to public, verify, and change back to private

Scenario: Username not found
  When the username does not exist on Steam
  Then I see "We couldn't find this profile on Steam. Is your custom URL different?"
```

---

### US-005 · View validation status `P0`
**As** a minor in the audit process,  
**I want** to see the status of all my registered accounts on one screen,  
**so that** I know which ones I have verified and which ones are pending.

**Acceptance Criteria:**
```gherkin
Scenario: Account dashboard view
  When I open the "My accounts" section
  Then I see a list with:
    - Platform name with its icon
    - My nickname on that platform
    - Status: "Pending" (⏳), "Verified" (✅), or "Failed" (❌)
    - Retry option for failed ones

Scenario: Expired window (24h)
  Given 24 hours have passed since I validated my email
  When I try to verify one more account
  Then I see "The 24-hour window has closed. We will generate your report with the already verified accounts."
```

---

### US-006 · Mark audit as ready `P0`
**As** a minor who has verified all the accounts they wanted,  
**I want** to indicate I am done adding accounts,  
**so that** SDIA generates my report with the collected information.

**Acceptance Criteria:**
```gherkin
Scenario: Mark as ready with at least 1 account
  Given I have at least 1 verified account
  When I press "Done! Generate my report"
  Then I see "Perfect! Your report will be ready tomorrow before 10:30 AM. It will arrive by email."
  And I cannot add more accounts

Scenario: Try to mark without verified accounts
  Given I have no verified accounts
  When I press "Generate my report"
  Then the button is disabled with tooltip "Verify at least one account first"
```

---

## Epic 3 — Report

### US-007 · Receive the report email `P0`
**As** a minor who completed the audit,  
**I want** to receive my PDF report by email with clear instructions to open it,  
**so that** I can review it with my family.

**Acceptance Criteria:**
```gherkin
Scenario: Email received
  Given my job is in REPORT_READY
  When the orchestrator finishes generating the report
  Then I receive an email with:
    - Subject: "Your digital footprint report is ready 🔍"
    - The PDF password (clearly highlighted)
    - A button/link to download the PDF
    - A note: "Share this password only with who you want to see it"
    - Reminder: "The link expires in 48 hours"

Scenario: Expired link after 48h
  When I try to download the PDF after 48h
  Then I receive HTTP 403 with a friendly message
```

---

### US-008 · Open and read the PDF report `P0`
**As** a minor (or parent/guardian),  
**I want** to open the PDF with the provided password and understand the findings,  
**so that** I can take concrete actions to improve my digital privacy.

**Acceptance Criteria:**
```gherkin
Scenario: PDF opens with correct password
  When I enter the password in Adobe Acrobat / Preview / PDF viewer
  Then I can read the full report

Scenario: Incorrect password
  When I enter an incorrect password
  Then the viewer shows "Incorrect password" (native reader behavior)

Scenario: Editing attempt
  When I try to edit or copy text from the PDF
  Then the action is blocked by the PDF permissions

Scenario: Printing allowed
  When I try to print the PDF
  Then I can print it (the only enabled action besides reading)
```

---

### US-009 · Understand the Risk Traffic Light `P0`
**As** a minor reading the report,  
**I want** to clearly see how risky my digital footprint is,  
**so that** I understand whether I need to take urgent action or just improve a few things.

**Acceptance Criteria:**
```gherkin
Scenario: HIGH risk (Red)
  Given the analysis detected high-risk signals (e.g. exact location exposed, LFG with strangers)
  Then the traffic light shows RED with text:
    "We found information that could put you at risk. We recommend reviewing this with an adult today."

Scenario: MEDIUM risk (Yellow)
  Then: "There are some things you can improve to be better protected"

Scenario: LOW risk (Green)
  Then: "Great job! Your digital footprint is well managed. Here are some tips to keep it that way."

Scenario: Per-platform traffic light
  Then each platform section has its own individual traffic light
```

---

## Epic 4 — Administration and Expiry

### US-010 · Automatic process expiry `P0`
**As** a user who did not complete the audit within 24h,  
**I want** my data to be automatically deleted,  
**so that** I have the assurance that my information does not persist in the system.

**Acceptance Criteria:**
```gherkin
Scenario: Expiry at 24h
  Given 24h have passed since my EMAIL_VALIDATED and I did not mark as ready
  When the system runs the verification process (or Cosmos TTL acts)
  Then my job moves to status EXPIRED
  And all data is auto-purged within the following 24h (total 48h TTL)
  And I receive no report

Scenario: Full purge at 48h
  Given my job was created 48h ago
  Regardless of status
  Then Cosmos DB automatically deletes the document
```

---

## Epic 5 — Future (v0.2+)

### US-011 · Choose report language `P2`
**As** a user who prefers English,  
**I want** to choose the report language (ES/EN),  
**so that** the information is accessible to my parents who do not speak Spanish.

### US-012 · Repeat audit to compare `P2`
**As** a minor who took actions from the remediation plan,  
**I want** to repeat the audit 30 days later,  
**so that** I can see if my risk score improved.

### US-013 · Age-adapted explanation `P2`
**As** a 9-year-old user,  
**I want** the report to use words I understand,  
**so that** I can read it without needing everything explained.
