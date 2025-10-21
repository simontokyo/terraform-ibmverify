import { test, expect } from '@playwright/test';
import Tesseract from 'tesseract.js';
import dotenv from 'dotenv';
import path from 'path';
import fs from 'fs';
import sharp from 'sharp';

// Load environment variables from .env file in the parent directory
const ENV_FILE_PATH = path.resolve(__dirname, '../.env');
dotenv.config({ path: ENV_FILE_PATH });

// Validate required environment variables
const ADMIN_URL = process.env.IBM_VERIFY_DASHBOARD_URL;
const ADMIN_EMAIL = process.env.IBM_VERIFY_ADMIN_EMAIL;
const ADMIN_PASSWORD = process.env.IBM_VERIFY_ADMIN_PASSWORD;

if (!ADMIN_URL) {
  throw new Error('IBM_VERIFY_DASHBOARD_URL is not set in .env file');
}

if (!ADMIN_EMAIL) {
  throw new Error('IBM_VERIFY_ADMIN_EMAIL is not set in .env file. Please add it to your .env file.');
}

if (!ADMIN_PASSWORD) {
  throw new Error('IBM_VERIFY_ADMIN_PASSWORD is not set in .env file. Please add it to your .env file.');
}

/**
 * Updates or adds API client credentials to the .env file
 */
function updateEnvFile(clientId: string, clientSecret: string): void {
  try {
    let envContent = fs.readFileSync(ENV_FILE_PATH, 'utf-8');
    
    // Check if API client credentials already exist
    const clientIdRegex = /^IBM_VERIFY_API_CLIENT_ID=.*$/m;
    const clientSecretRegex = /^IBM_VERIFY_API_CLIENT_SECRET=.*$/m;
    
    if (clientIdRegex.test(envContent)) {
      // Update existing Client ID
      envContent = envContent.replace(clientIdRegex, `IBM_VERIFY_API_CLIENT_ID=${clientId}`);
    } else {
      // Add new Client ID
      envContent = envContent.replace(
        /^# IBM_VERIFY_API_CLIENT_ID=.*$/m,
        `IBM_VERIFY_API_CLIENT_ID=${clientId}`
      );
    }
    
    if (clientSecretRegex.test(envContent)) {
      // Update existing Client Secret
      envContent = envContent.replace(clientSecretRegex, `IBM_VERIFY_API_CLIENT_SECRET=${clientSecret}`);
    } else {
      // Add new Client Secret
      envContent = envContent.replace(
        /^# IBM_VERIFY_API_CLIENT_SECRET=.*$/m,
        `IBM_VERIFY_API_CLIENT_SECRET=${clientSecret}`
      );
    }
    
    // Write the updated content back to the file
    fs.writeFileSync(ENV_FILE_PATH, envContent, 'utf-8');
    console.log('Successfully updated .env file with API client credentials');
  } catch (error) {
    console.error('Error updating .env file:', error);
    throw error;
  }
}


async function recognizePassword(imagePath: string): Promise<string> {
  // Read image file
  const buffer = fs.readFileSync(imagePath);
  
  // Run OCR with optimized settings
  const result = await Tesseract.recognize(imagePath, 'eng', {
    // tessedit_char_whitelist: 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_',
    tessedit_pageseg_mode: Tesseract.PSM.SINGLE_LINE,
    // preserve_interword_spaces: '0',
    // tessedit_char_blacklist: '|[]{}()<>',
  } as any);
  console.log('OCR result:', result.data.text);
  
  return result.data.text.trim().split(' ')[0];
}

test('Create API Client in IBM Verify Admin UI', async ({ page }) => {
  // Set longer timeout for slow operations
  page.setDefaultTimeout(60000);
  
  // Navigate to IBM Verify Admin UI
  await page.goto(ADMIN_URL);
  await page.context().storageState({ path: 'auth.json' });
  
  // Login with IBM ID
  await page.getByRole('textbox', { name: 'IBMid' }).fill(ADMIN_EMAIL);
  await page.getByRole('button', { name: 'Continue' }).click();
  await page.locator('#credsDiv').click();
  
  // Enter credentials
  await page.getByRole('textbox', { name: 'IBM email address (e.g. jdoe@' }).fill(ADMIN_EMAIL);
  await page.getByRole('textbox', { name: 'Password' }).fill(ADMIN_PASSWORD);
  await page.getByRole('button', { name: 'Sign in' }).click();
  
  // Accept cookies and navigate to API access
  await page.getByRole('button', { name: 'Accept all' }).click();
  await page.getByRole('button', { name: 'Security' }).click();
  await page.getByRole('link', { name: 'API access' }).click();
  await page.getByRole('button', { name: 'Add API client' }).click();
  await page.getByLabel('Create API client').locator('label').filter({ hasText: 'Select all rows' }).click();
  await page.locator('#walkme-visual-design-3ee96fc6-3cb8-27f6-03e5-d07949724baa').getByRole('button', { name: 'Close' }).click();

  await page.getByRole('button', { name: 'Next', exact: true }).click();
  await page.getByRole('button', { name: 'Next', exact: true }).click();
  await page.getByRole('button', { name: 'Next', exact: true }).click();
  await page.getByRole('button', { name: 'Next', exact: true }).click();
  await page.getByRole('button', { name: 'Next', exact: true }).click();
  await page.getByRole('textbox', { name: 'Name' }).fill('test api 002');
  await page.getByRole('button', { name: 'Create API client' }).click();
  
  // Click the first Options button
  await page.getByRole('button', { name: 'Options' }).last().click();
  await page.getByRole('menuitem', { name: 'Connection details' }).click();
  await page.getByRole('button', { name: 'Show password' }).click();

  // パスワードが表示されるまで待機（type="text"になるのを確認）
  await page.waitForFunction(() => {
    const el = document.querySelector('#ci-api-clients-password-input');
    return el && el.getAttribute('type') === 'text';
  });
  await page.waitForTimeout(1000);
  
  // Extract Client ID
  const clientId = await page.locator('#ci-api-clients-client-id-input').inputValue();
  console.log('Client ID:', clientId);

  // Extract Client Secret via OCR
  const wrapper = page.locator('#ci-api-clients-password-input').locator('..');
  const screenshotPath = path.resolve(__dirname, 'client-secret-field.png');
  await wrapper.evaluate((el) => {
    el.style.transform = 'scale(1.6)';
    el.style.transformOrigin = 'top left';
  });
  await wrapper.screenshot({ path: screenshotPath, type: 'png', scale: 'device',});
  console.log('Screenshot saved:', screenshotPath);

  try {
    // Use OCR with preprocessing to extract the client secret
    const clientSecret = await recognizePassword(screenshotPath);
    console.log('Extracted Client Secret:', clientSecret);
    
    // Update the .env file with the extracted credentials
    if (clientId) {
      updateEnvFile(clientId, clientSecret || 'MANUAL_ENTRY_REQUIRED');
      console.log('\nSUCCESS: API Client credentials saved to .env file:');
      console.log(`   IBM_VERIFY_API_CLIENT_ID=${clientId}`);
      console.log(`   IBM_VERIFY_API_CLIENT_SECRET=${clientSecret || 'MANUAL_ENTRY_REQUIRED'}`);
      if (!clientSecret) {
        console.warn('WARNING: Client Secret not extracted. Check screenshot and update .env manually');
      }
    } else {
      console.warn('WARNING: Client ID is empty, .env file not updated');
    }
  } catch (err) {
    console.error('ERROR: OCR failed:', err);
    console.log('Tip: Check the screenshot file and extract the secret manually');
    throw err;
  }
});
