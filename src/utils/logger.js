/**
 * Logging utility for workflow operations
 */

class Logger {
  constructor(context = 'App') {
    this.context = context;
  }

  /**
   * Log informational message
   * @param {string} message - Log message
   * @param {object} data - Additional data to log
   */
  info(message, data = {}) {
    console.log(JSON.stringify({
      level: 'info',
      context: this.context,
      message,
      data,
      timestamp: new Date().toISOString()
    }));
  }

  /**
   * Log error message
   * @param {string} message - Error message
   * @param {Error} error - Error object
   */
  error(message, error = null) {
    console.error(JSON.stringify({
      level: 'error',
      context: this.context,
      message,
      error: error ? {
        message: error.message,
        stack: error.stack
      } : null,
      timestamp: new Date().toISOString()
    }));
  }

  /**
   * Log warning message
   * @param {string} message - Warning message
   * @param {object} data - Additional data to log
   */
  warn(message, data = {}) {
    console.warn(JSON.stringify({
      level: 'warn',
      context: this.context,
      message,
      data,
      timestamp: new Date().toISOString()
    }));
  }

  /**
   * Log debug message
   * @param {string} message - Debug message
   * @param {object} data - Additional data to log
   */
  debug(message, data = {}) {
    if (process.env.DEBUG === 'true') {
      console.debug(JSON.stringify({
        level: 'debug',
        context: this.context,
        message,
        data,
        timestamp: new Date().toISOString()
      }));
    }
  }
}

module.exports = Logger;
