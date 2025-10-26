/**
 * Deduplication utility for job listings
 */

class JobDeduplicator {
  /**
   * Remove duplicate job listings based on title and company
   * @param {array} jobs - Array of job listings
   * @returns {array} - Deduplicated job listings
   */
  static deduplicate(jobs) {
    const seen = new Set();
    const unique = [];

    for (const job of jobs) {
      const key = `${job.title}::${job.company}`.toLowerCase();
      
      if (!seen.has(key)) {
        seen.add(key);
        unique.push(job);
      }
    }

    return unique;
  }

  /**
   * Merge job listings from multiple sources
   * @param {array} sources - Array of job listing arrays
   * @returns {array} - Merged and deduplicated listings
   */
  static mergeAndDeduplicate(...sources) {
    const allJobs = sources.flat();
    return this.deduplicate(allJobs);
  }
}

module.exports = JobDeduplicator;
