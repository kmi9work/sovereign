import { CONFIG } from '../config';

const BASE_URL = CONFIG.API_BASE_URL;

async function request<T>(path: string, options: RequestInit = {}): Promise<T> {
  const url = `${BASE_URL}${path}`;
  const config: RequestInit = {
    headers: {
      'Content-Type': 'application/json',
      Accept: 'application/json',
    },
    ...options,
  };

  const response = await fetch(url, config);
  const data = await response.json();

  if (!response.ok) {
    throw new Error(data.error || data.errors?.join(', ') || 'Request failed');
  }

  return data as T;
}

export interface Country {
  id: number;
  name: string;
}

export interface ActionType {
  id: number;
  action_type: string;
  name: string;
  display_params: string;
  success_result: string;
  failure_result: string;
}

export interface Position {
  id: number;
  name: string;
  country_id: number;
  action_types: ActionType[];
  action_type_counts: Record<string, number>;
}

export interface Province {
  id: number;
  name: string;
  country_name?: string;
}

export interface ActionTypeWithLists {
  action_type: ActionType;
  other_countries: Country[];
  provinces_of_country: Province[];
  provinces_of_other: Province[];
}

export interface ActionItem {
  id: number;
  position_id: number;
  action_type_id: number;
  country_id: number;
  second_country_id: number | null;
  province_id: number | null;
  cycle_number: number;
  read: boolean;
  result: boolean;
  created_at: string;
  updated_at: string;
  position: { id: number; name: string };
  action_type: ActionType;
  country: { id: number; name: string };
  second_country: { id: number; name: string } | null;
  province: { id: number; name: string } | null;
}

export function getCountries(): Promise<Country[]> {
  return request<Country[]>('/api/v1/countries');
}

export function getCountriesWithPositions(): Promise<Country[]> {
  return request<Country[]>('/api/v1/countries/with_positions');
}

export function getPositionsWithActions(countryId: number): Promise<Position[]> {
  return request<Position[]>(`/api/v1/countries/${countryId}/positions`);
}

export function getActionTypeWithLists(
  actionTypeId: number,
  countryId: number,
): Promise<ActionTypeWithLists> {
  return request<ActionTypeWithLists>(
    `/api/v1/action_types/${actionTypeId}/with_lists?country_id=${countryId}`,
  );
}

export function performAction(params: {
  position_id: number;
  action_type_id: number;
  result: boolean;
  country_id?: number;
  second_country_id?: number;
  province_id?: number;
}): Promise<ActionItem> {
  return request<ActionItem>('/api/v1/actions/perform', {
    method: 'POST',
    body: JSON.stringify(params),
  });
}

export function getCurrentCycleActions(countryId: number): Promise<ActionItem[]> {
  return request<ActionItem[]>(
    `/api/v1/countries/${countryId}/actions/current_cycle`,
  );
}

export function markActionRead(actionId: number): Promise<ActionItem> {
  return request<ActionItem>(`/api/v1/actions/${actionId}/mark_read`, {
    method: 'PATCH',
  });
}

export function getCurrentCycle(): Promise<{ id: number; current_cycle: number }> {
  return request('/api/v1/parameters');
}

export function nextCycle(): Promise<{ id: number; current_cycle: number }> {
  return request('/api/v1/parameters/next_cycle', { method: 'POST' });
}

export function prevCycle(): Promise<{ id: number; current_cycle: number }> {
  return request('/api/v1/parameters/prev_cycle', { method: 'POST' });
}
