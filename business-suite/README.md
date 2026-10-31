# IMMORTAL SOLUTION — Business Suite

A separate deployable website and staff operations portal for IMMORTAL SOLUTION. This application is kept under `business-suite/` so the existing website at the repository root remains unchanged.

## Technology
- HTML, CSS and JavaScript modules
- Vite production build
- Supabase Auth and PostgreSQL with Row Level Security
- Netlify hosting
- GitHub Actions build and Playwright browser checks

## Netlify deployment
Create a **separate Netlify site** connected to this repository:
- Repository: `guptacommunicationservices-spec/immortal-solution`
- Branch: `business-suite`
- Base directory: `business-suite`
- Build command: `npm run build`
- Publish directory: `dist`
- Node: 22

Add Netlify environment variables:
- `VITE_SUPABASE_URL`: the existing Supabase project URL
- `VITE_SUPABASE_PUBLISHABLE_KEY`: the project's publishable key (never use a service-role key in a browser variable)

For automatic GitHub Actions deployment, configure repository Actions secrets:
- `NETLIFY_AUTH_TOKEN`
- `NETLIFY_SITE_ID`
- `VITE_SUPABASE_URL`
- `VITE_SUPABASE_PUBLISHABLE_KEY`
- Optional live admin test: `E2E_BASE_URL`, `E2E_ADMIN_EMAIL`, `E2E_ADMIN_PASSWORD`

## Supabase database
The migration is included at `business-suite/supabase/migrations/002_immortal_business_suite.sql`. It was previously applied to the active Supabase project. It creates the staff role, enquiries, property, vacancies, candidate applications, blog posts and follow-up task tables with Row Level Security.

After the first administrator account is registered and email-confirmed, provision the owner role in the Supabase SQL editor (replace the email with the exact administrator email):

```sql
insert into public.staff_roles (user_id, role)
select id, 'owner'
from auth.users
where lower(email) = lower('YOUR-ADMIN-EMAIL@example.com')
on conflict (user_id) do update set role = excluded.role;
```

Do not expose service-role keys in frontend code or GitHub source. Do not enable public role registration.

## Included modules
- Public company website: Home, Services, About, Properties, Careers, Insights and Contact
- Service enquiry capture
- Candidate application capture
- Staff sign-in with Supabase Auth
- Admin overview dashboard
- Enquiry CRM and status management
- Property listing management
- Vacancy management
- Candidate application tracking
- Blog post management
- Follow-up task management

## Local development
```bash
cd business-suite
npm install
npm run dev
```

Production build:
```bash
npm run build
```

Browser tests:
```bash
npx playwright install chromium
npm run test:e2e
```

## Production checklist
1. Create the separate Netlify site using the settings above.
2. Add Supabase environment variables to Netlify.
3. Set Supabase Auth Site URL and allowed redirect URL to the new Netlify domain.
4. Create/confirm the first admin account and provision its owner role.
5. Add Netlify deployment secrets to GitHub Actions.
6. Run the build and browser tests.
7. Add suitable spam protection, privacy notices, data retention and consent workflows before collecting substantial candidate or customer data.

The existing repository root and its current Netlify site are not replaced by this subdirectory deployment.
