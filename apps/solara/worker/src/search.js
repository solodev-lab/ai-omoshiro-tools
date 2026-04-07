/**
 * Place Name Search — Nominatim (primary) → Google Places (fallback)
 * Nominatim: free, 1 req/sec, no autocomplete (confirmed button only)
 * Google Places: env.GOOGLE_PLACES_KEY required, 10k/month free
 */

const NOMINATIM_URL = 'https://nominatim.openstreetmap.org/search';
const NOMINATIM_UA = 'SolaraApp/1.0 (solodev-lab.com)';

export async function searchPlace(query, env) {
  // Try Nominatim first
  const nominatimResults = await searchNominatim(query);
  if (nominatimResults.length > 0) return { source: 'nominatim', results: nominatimResults };

  // Fallback to Google Places if API key is set
  if (env && env.GOOGLE_PLACES_KEY) {
    const googleResults = await searchGooglePlaces(query, env.GOOGLE_PLACES_KEY);
    return { source: 'google', results: googleResults };
  }

  return { source: 'nominatim', results: [] };
}

async function searchNominatim(query) {
  const params = new URLSearchParams({
    q: query,
    format: 'json',
    limit: '5',
    addressdetails: '1',
  });

  const resp = await fetch(`${NOMINATIM_URL}?${params}`, {
    headers: { 'User-Agent': NOMINATIM_UA, 'Accept-Language': 'ja,en' }
  });

  if (!resp.ok) return [];

  const data = await resp.json();
  return data.map(item => ({
    name: item.display_name,
    lat: parseFloat(item.lat),
    lng: parseFloat(item.lon),
    type: item.type,
    country: item.address?.country || '',
    countryCode: item.address?.country_code || '',
  }));
}

async function searchGooglePlaces(query, apiKey) {
  const params = new URLSearchParams({
    input: query,
    inputtype: 'textquery',
    fields: 'formatted_address,geometry,name',
    key: apiKey,
  });

  const resp = await fetch(
    `https://maps.googleapis.com/maps/api/place/findplacefromtext/json?${params}`
  );

  if (!resp.ok) return [];

  const data = await resp.json();
  if (!data.candidates) return [];

  return data.candidates.map(c => ({
    name: c.formatted_address || c.name,
    lat: c.geometry?.location?.lat,
    lng: c.geometry?.location?.lng,
    type: 'place',
    country: '',
    countryCode: '',
  }));
}
