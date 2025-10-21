import Tesseract from 'tesseract.js';
import fs from 'fs';
import path from 'path';
import sharp from 'sharp';

async function recognizePassword(imagePath: string): Promise<string> {
  console.log('Reading image:', imagePath);
  
  // Check if file exists
  if (!fs.existsSync(imagePath)) {
    throw new Error(`File not found: ${imagePath}`);
  }
  
  const buffer = fs.readFileSync(imagePath);
  console.log('Image size:', buffer.length, 'bytes');
  
  // Inspect image metadata
  const metadata = await sharp(imagePath).metadata();
  console.log('Image dimensions:', metadata.width, 'x', metadata.height);
  console.log('Image format:', metadata.format);
  console.log('Image channels:', metadata.channels);
  
  // Check image statistics
  const stats = await sharp(imagePath).stats();
  console.log('Image is mostly:', stats.isOpaque ? 'opaque' : 'transparent');
  console.log('');
  
  // Create enhanced version for better OCR
  const enhancedPath = imagePath.replace('.png', '-enhanced.png');
  await sharp(imagePath)
    .resize({ width: metadata.width! * 3 }) // Upscale 3x
    .greyscale()
    .normalize()
    .sharpen()
    .toFile(enhancedPath);
  console.log('Enhanced image saved:', enhancedPath);
  console.log('');
  
  // Run OCR with optimized settings
  console.log('Starting OCR processing...');
  const result = await Tesseract.recognize(enhancedPath, 'eng', {
    logger: (m) => console.log('Tesseract:', m.status, m.progress ? `${(m.progress * 100).toFixed(0)}%` : ''),
    tessedit_char_whitelist: 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_',
    tessedit_pageseg_mode: Tesseract.PSM.SINGLE_LINE,
    preserve_interword_spaces: '0',
    tessedit_char_blacklist: '|[]{}()<>',
  } as any);
  
  console.log('OCR processing complete!');
  
  // Clean up enhanced image
  if (fs.existsSync(enhancedPath)) {
    fs.unlinkSync(enhancedPath);
  }
  
  console.log('OCR raw result:', result.data.text);
  console.log('OCR confidence:', result.data.confidence);
  
  const cleaned = result.data.text.trim().split(' ')[0];
  
  return cleaned;
}

async function main() {
  const screenshotPath = path.resolve(__dirname, 'client-secret-field.png');
  
  console.log('=== OCR Test Script ===');
  console.log('Target file:', screenshotPath);
  console.log('');
  
  try {
    const clientSecret = await recognizePassword(screenshotPath);
    
    console.log('');
    console.log('=== Results ===');
    console.log('Extracted text:', clientSecret);
    console.log('Length:', clientSecret.length);
    console.log('');
    
    if (clientSecret) {
      console.log('SUCCESS: Client Secret extracted');
    } else {
      console.log('WARNING: Client Secret is empty');
    }
  } catch (error) {
    console.error('ERROR:', error);
    process.exit(1);
  }
}

main();

