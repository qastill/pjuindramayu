const { supabase } = require('../lib/supabase');

module.exports = async (req, res) => {
  if (req.method === 'GET') {
    const { status, limit = 50 } = req.query;
    let query = supabase.from('pengaduan').select('*');
    if (status && status !== 'all') query = query.eq('status', status);
    query = query.limit(parseInt(limit)).order('created_at', { ascending: false });
    const { data, error } = await query;
    if (error) return res.status(500).json({ error: error.message });
    return res.json(data);
  }

  if (req.method === 'POST') {
    const { data, error } = await supabase
      .from('pengaduan')
      .insert(req.body)
      .select()
      .single();
    if (error) return res.status(400).json({ error: error.message });
    return res.status(201).json(data);
  }

  if (req.method === 'PUT') {
    const { id, ...updates } = req.body;
    if (!id) return res.status(400).json({ error: 'ID required' });
    updates.updated_at = new Date().toISOString();
    const { data, error } = await supabase
      .from('pengaduan')
      .update(updates)
      .eq('id', id)
      .select()
      .single();
    if (error) return res.status(400).json({ error: error.message });
    return res.json(data);
  }

  res.status(405).json({ error: 'Method not allowed' });
};
