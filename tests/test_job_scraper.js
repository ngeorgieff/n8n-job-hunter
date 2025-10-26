/**
 * Test suite for Apify integration
 */

const ApifyIntegration = require('../src/integrations/apify');

describe('Apify Integration', () => {
  let apifyClient;

  beforeEach(() => {
    apifyClient = new ApifyIntegration('test-api-key');
  });

  test('should initialize with API key', () => {
    expect(apifyClient.apiKey).toBe('test-api-key');
    expect(apifyClient.baseUrl).toBe('https://api.apify.com/v2');
  });

  test('should run actor with input', async () => {
    const result = await apifyClient.runActor('test-actor-id', {
      url: 'https://example.com/jobs'
    });
    
    expect(result).toHaveProperty('status');
    expect(result.status).toBe('success');
  });

  test('should get run results', async () => {
    const result = await apifyClient.getRunResults('test-run-id');
    
    expect(result).toHaveProperty('status');
    expect(result).toHaveProperty('data');
  });
});
