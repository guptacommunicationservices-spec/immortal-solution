import { test, expect } from '@playwright/test';

test('public home page renders core business sections', async ({ page }) => {
  await page.goto('/');
  await expect(page).toHaveTitle(/IMMORTAL SOLUTION/);
  await expect(page.getByRole('heading', { level: 1 })).toContainText('Ideas into action');
  await expect(page.locator('#services')).toBeVisible();
  await expect(page.locator('#properties')).toBeVisible();
  await expect(page.locator('#careers')).toBeVisible();
  await expect(page.locator('#contact')).toBeVisible();
});

test('service enquiry shortcut preselects the requested service', async ({ page }) => {
  await page.goto('/');
  await page.locator('[data-service="Recruitment, HR & Manpower"]').click();
  await expect(page.locator('#leadForm select[name="service"]')).toHaveValue('Recruitment, HR & Manpower');
});

test('candidate application form is available', async ({ page }) => {
  await page.goto('/');
  await expect(page.locator('#applicationForm input[name="candidate_name"]')).toBeVisible();
  await expect(page.locator('#applicationForm input[name="email"]')).toHaveAttribute('type', 'email');
  await expect(page.locator('#applicationForm input[name="phone"]')).toBeVisible();
});

test('staff sign-in dialog opens', async ({ page }) => {
  await page.goto('/');
  await page.getByRole('button', { name: 'Admin Login' }).click();
  await expect(page.getByRole('heading', { name: 'Admin sign in' })).toBeVisible();
});

test('pre-authorised administrator can authenticate and open the dashboard', async ({ page }) => {
  test.skip(
    !process.env.E2E_ADMIN_EMAIL ||
    !process.env.E2E_ADMIN_PASSWORD ||
    !process.env.VITE_SUPABASE_URL ||
    !process.env.VITE_SUPABASE_PUBLISHABLE_KEY,
    'Set GitHub Actions secrets for a dedicated pre-authorised test administrator to enable live authentication testing.'
  );

  await page.goto('/');
  await page.getByRole('button', { name: 'Admin Login' }).click();
  await page.locator('#login input[name="email"]').fill(process.env.E2E_ADMIN_EMAIL);
  await page.locator('#login input[name="password"]').fill(process.env.E2E_ADMIN_PASSWORD);
  await page.locator('#login button[type="submit"]').click();
  await expect(page.getByRole('heading', { name: 'Business overview' })).toBeVisible({ timeout: 20_000 });
  await expect(page.locator('.admin')).toBeVisible();
});
