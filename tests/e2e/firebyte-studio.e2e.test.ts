import { test, expect, Page } from '@playwright/test';

test.describe('Firebyte Studio E2E Tests', () => {
  test.beforeEach(async ({ page }: { page: Page }) => {
    await page.goto('http://localhost:8000');
  });

  test('Unauthenticated user sees dashboard but protected features are disabled', async ({ page }: { page: Page }) => {
    await expect(page.locator('text=Dashboard')).toBeVisible();
    await expect(page.locator('text=New AI Project')).toBeVisible();
    await expect(page.locator('text=Import from Figma')).toBeVisible();
    // Try clicking New AI Project and expect redirect to login
    await page.click('text=New AI Project >> button:has-text("Get Started")');
    await expect(page).toHaveURL(/\/login/);
  });

  test('Login flow with Google and GitHub', async ({ page }: { page: Page }) => {
    await page.goto('http://localhost:8000/login');
    await expect(page.locator('text=Sign in with Google')).toBeVisible();
    await expect(page.locator('text=Sign in with GitHub')).toBeVisible();
    // Note: Actual OAuth flow requires manual or mock
  });

  test('Create new AI project via wizard', async ({ page }: { page: Page }) => {
    // Mock login
    await page.evaluate(() => {
      sessionStorage.setItem('fb_user', 'test_user');
    });
    await page.goto('http://localhost:8000');
    await page.click('text=New AI Project >> button:has-text("Get Started")');
    // Step 1: Select template
    await page.click('button:has-text("SaaS Dashboard")');
    await page.click('button:has-text("Next")');
    // Step 2: Select modules
    await page.click('button:has-text("Chatbot")');
    await page.click('button:has-text("Next")');
    // Step 3: Select deploy platform
    await page.click('button:has-text("Vercel")');
    await page.click('button:has-text("Create Project")');
    // Expect redirect to project page
    await expect(page).toHaveURL(/\/projects\/.+/);
  });

  test('Project list and detail pages', async ({ page }: { page: Page }) => {
    await page.goto('http://localhost:8000/projects');
    await expect(page.locator('text=Projects')).toBeVisible();
    // Click first project view details
    await page.click('button:has-text("View Details")');
    await expect(page.locator('text=Project Overview')).toBeVisible();
  });

  test('AI Chat interaction', async ({ page }: { page: Page }) => {
    await page.goto('http://localhost:8000/ai-chat');
    await page.fill('textarea[placeholder*="Ask me anything"]', 'Hello AI');
    await page.click('button:has-text("Send")');
    await expect(page.locator('text=AI is thinking')).toBeVisible();
    // Wait for response
    await page.waitForTimeout(3000);
    await expect(page.locator('text=Hello AI')).toBeVisible();
  });

  test('E-commerce AI generation', async ({ page }: { page: Page }) => {
    await page.goto('http://localhost:8000/ecommerce-ai');
    await page.fill('input#productName', 'Wireless Headphones');
    await page.selectOption('select', 'Electronics');
    await page.click('button:has-text("Generate Product Content")');
    await expect(page.locator('text=Generated Content')).toBeVisible();
  });

  test('Figma import simulation', async ({ page }: { page: Page }) => {
    await page.goto('http://localhost:8000/figma-import');
    await page.fill('input#figmaUrl', 'https://www.figma.com/file/abc123/Design?node-id=1%3A2');
    await page.click('button:has-text("Import Design")');
    await expect(page.locator('text=Import in progress')).toBeVisible();
    await page.waitForTimeout(2500);
    await expect(page.locator('text=Import Results')).toBeVisible();
  });

  test('Logout flow', async ({ page }: { page: Page }) => {
    await page.goto('http://localhost:8000');
    // Simulate logged in user
    await page.evaluate(() => sessionStorage.setItem('fb_user', 'test_user'));
    await page.reload();
    await page.click('button[aria-label="Logout"]');
    await expect(page).toHaveURL('/');
    await expect(page.locator('text=Sign In')).toBeVisible();
  });
});
