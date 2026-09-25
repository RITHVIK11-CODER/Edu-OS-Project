const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:8000/api/v1';

export type ApiError = { code?: string; message?: string; details?: unknown };

async function request<T>(path: string, options: RequestInit = {}): Promise<T> {
  const token = localStorage.getItem('eduos_access_token');
  const headers = new Headers(options.headers);
  headers.set('Content-Type', 'application/json');
  headers.set('Accept', 'application/json');
  headers.set('X-Request-ID', crypto.randomUUID());
  if (token && !token.startsWith('demo-')) headers.set('Authorization', `Bearer ${token}`);

  const res = await fetch(`${API_BASE_URL}${path}`, { ...options, headers });
  const body = await res.json().catch(() => ({}));

  if (!res.ok || body.success === false) {
    const message = body?.error?.message || body?.detail || `Request failed (${res.status})`;
    throw new Error(message);
  }

  return body.data as T;
}

export const api = {
  login: async (email: string, password: string) => {
    const data = await request<any>('/auth/login', {
      method: 'POST',
      body: JSON.stringify({ email, password })
    });
    localStorage.setItem('eduos_access_token', data.access_token);
    return data;
  },
  me: () => request<any>('/auth/me'),
  student: () => request<any>('/students/me'),
  twin: () => request<any>('/students/me/learning-twin'),

  // Contract endpoint. Backend must provide GET /assessments.
  assessments: () => request<any[]>('/assessments'),

  start: (id: string) => request<any>(`/assessments/${id}/start`, { method: 'POST' }),
  questions: (id: string) => request<any[]>(`/assessments/${id}/questions`),

  answer: (id: string, body: {
    question_id: string;
    student_answer: string;
    time_taken_seconds?: number;
  }) => request<any>(`/attempts/${id}/answers`, {
    method: 'POST',
    body: JSON.stringify(body)
  }),

  submit: (id: string) => request<any>(`/attempts/${id}/submit`, { method: 'POST' }),
  result: (id: string) => request<any>(`/attempts/${id}/result`),

  mindtrace: (answerId: string) => request<any>('/mindtrace/analyze', {
    method: 'POST',
    body: JSON.stringify({ answer_id: answerId })
  }),

  pathai: (conceptId: string) => request<any>('/pathai/recommend', {
    method: 'POST',
    body: JSON.stringify({ concept_id: conceptId })
  })
};

export const logout = () => localStorage.removeItem('eduos_access_token');
