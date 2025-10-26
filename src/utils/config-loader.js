/**
 * Configuration loader utility
 */

const fs = require('fs');
const path = require('path');

class ConfigLoader {
  /**
   * Load environment variables from .env file
   * @param {string} envPath - Path to .env file
   * @returns {object} - Environment configuration
   */
  static loadEnv(envPath = '.env') {
    if (!fs.existsSync(envPath)) {
      throw new Error(`Environment file not found: ${envPath}`);
    }

    const config = {};
    const content = fs.readFileSync(envPath, 'utf-8');
    
    content.split('\n').forEach(line => {
      const trimmed = line.trim();
      if (trimmed && !trimmed.startsWith('#')) {
        const [key, ...valueParts] = trimmed.split('=');
        const value = valueParts.join('=').trim();
        config[key.trim()] = value;
      }
    });

    return config;
  }

  /**
   * Validate required configuration keys
   * @param {object} config - Configuration object
   * @param {array} requiredKeys - Required configuration keys
   * @throws {Error} - If required keys are missing
   */
  static validate(config, requiredKeys) {
    const missing = requiredKeys.filter(key => !config[key]);
    
    if (missing.length > 0) {
      throw new Error(`Missing required configuration: ${missing.join(', ')}`);
    }
  }
}

module.exports = ConfigLoader;
