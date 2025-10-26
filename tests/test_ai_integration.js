/**
 * Test suite for AI integration
 */

const OpenRouterIntegration = require('../src/integrations/openrouter');

describe('OpenRouter AI Integration', () => {
  let aiClient;

  beforeEach(() => {
    aiClient = new OpenRouterIntegration('test-api-key');
  });

  test('should initialize with API key', () => {
    expect(aiClient.apiKey).toBe('test-api-key');
    expect(aiClient.baseUrl).toBe('https://openrouter.ai/api/v1');
  });

  test('should analyze job match', async () => {
    const job = {
      title: 'Software Engineer',
      company: 'Tech Corp',
      description: 'Build great software'
    };
    
    const profile = {
      skills: ['JavaScript', 'Node.js', 'React']
    };
    
    const result = await aiClient.analyzeMatch(job, profile);
    
    expect(result).toHaveProperty('matchScore');
    expect(result).toHaveProperty('reasoning');
    expect(result).toHaveProperty('recommendations');
  });

  test('should generate resume', async () => {
    const profile = { name: 'John Doe' };
    const job = { title: 'Developer' };
    
    const resume = await aiClient.generateResume(profile, job);
    
    expect(typeof resume).toBe('string');
  });

  test('should generate cover letter', async () => {
    const profile = { name: 'John Doe' };
    const job = { title: 'Developer' };
    
    const coverLetter = await aiClient.generateCoverLetter(profile, job);
    
    expect(typeof coverLetter).toBe('string');
  });

  test('should support adding new models', () => {
    expect(() => {
      aiClient.addModel('custom-model', { temperature: 0.7 });
    }).not.toThrow();
  });
});
