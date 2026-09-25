const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:8000/api/v1';

export type ApiError = { code?: string; message?: string; details?: unknown };

async function request<T>(path:string, options:RequestInit = {}):Promise<T>{
  const token = localStorage.getItem('eduos_access_token');
  const headers = new Headers(options.headers);
  headers.set('Content-Type','application/json');
  headers.set('Accept','application/json');
  if(token) headers.set('Authorization',`Bearer ${token}`);
  const res = await fetch(`${API_BASE_URL}${path}`,{...options,headers});
  const body = await res.json().catch(()=>({}));
  if(!res.ok || body.success === false){
    const error = body.error as ApiError | undefined;
    throw new Error(error?.message || `Request failed (${res.status})`);
  }
  return body.data as T;
}

export const api = {
  async login(email:string,password:string){
    const data = await request<{access_token:string;refresh_token?:string;token_type:string;user:{id:string;role:string;display_name?:string}}>(
      '/auth/login',{method:'POST',body:JSON.stringify({email,password})});
    localStorage.setItem('eduos_access_token',data.access_token);
    return data;
  },
  me:()=>request<{id:string;role:string;display_name?:string}>('/auth/me'),
  student:()=>request<Record<string,unknown>>('/students/me'),
  twin:()=>request<Record<string,unknown>>('/learning-twin/me'),
  assessments:()=>request<unknown[]>('/assessments'),
  start:(id:string)=>request<{attempt_id:string;status:string;started_at:string}>(`/assessments/${id}/start`,{method:'POST'}),
  questions:(id:string)=>request<unknown[]>(`/assessments/${id}/questions`),
  answer:(attemptId:string,body:Record<string,unknown>)=>request<unknown>(`/attempts/${attemptId}/answers`,{method:'POST',body:JSON.stringify(body)}),
  submit:(attemptId:string)=>request<Record<string,unknown>>(`/attempts/${attemptId}/submit`,{method:'POST'}),
  result:(attemptId:string)=>request<Record<string,unknown>>(`/attempts/${attemptId}/result`),
  mindtrace:(answerId:string)=>request<Record<string,unknown>>('/mindtrace/analyze',{method:'POST',body:JSON.stringify({answer_id:answerId})}),
  pathai:(conceptId:string)=>request<Record<string,unknown>>('/pathai/recommend',{method:'POST',body:JSON.stringify({concept_id:conceptId})}),
};

export function logout(){localStorage.removeItem('eduos_access_token');}
