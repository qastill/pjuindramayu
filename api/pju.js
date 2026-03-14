const { supabase } = require('../lib/supabase');

module.exports = async (req, res) => {
  if (req.method === 'GET') {
    const { meter_id, gardu, status, limit = 500 } = req.query;
    let query = supabase.from('pju_points').select('*, kwh_meters(gardu, ulp)');
    if (meter_id) query = query.eq('meter_id', meter_id);
    if (gardu) query = query.eq('gardu', gardu);
    if (status) query = query.eq('status', status);
    query = query.limit(parseInt(limit)).order('created_at', { ascending: false });
    const { data, error } = await query;
    if (error) return res.status(500).json({ error: error.message });
    return res.json(data);
  }

  if (req.method === 'POST') {
    const body = req.body;
    // Auto-link to meter by gardu name
    if (body.gardu && !body.meter_id) {
      const { data: meter } = await supabase
        .from('kwh_meters')
        .select('id')
        .eq('gardu', body.gardu)
        .single();
      if (meter) body.meter_id = meter.id;
    }
    const { data, error } = await supabase
      .from('pju_points')
      .insert(body)
      .select()
      .single();
    if (error) return res.status(400).json({ error: error.message });

    // Update meter PJU count
    if (body.gardu) {
      const { count } = await supabase
        .from('pju_points')
        .select('*', { count: 'exact', head: true })
        .eq('gardu', body.gardu);
      const totalDaya = await supabase
        .from('pju_points')
        .select('daya')
        .eq('gardu', body.gardu);
      const sumDaya = (totalDaya.data || []).reduce((a, p) => a + (p.daya || 0), 0);
      await supabase
        .from('kwh_meters')
        .update({ jml_pju: count, total_daya: sumDaya })
        .eq('gardu', body.gardu);
    }

    return res.status(201).json(data);
  }

  res.status(405).json({ error: 'Method not allowed' });
};
