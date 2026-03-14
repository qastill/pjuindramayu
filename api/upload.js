const { supabase } = require('../lib/supabase');

module.exports = async (req, res) => {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    // Expect base64 image in body
    const { image, filename, folder = 'uploads' } = req.body;
    if (!image) return res.status(400).json({ error: 'No image provided' });

    // Decode base64
    const base64Data = image.replace(/^data:image\/\w+;base64,/, '');
    const buffer = Buffer.from(base64Data, 'base64');
    const ext = image.match(/data:image\/(\w+)/)?.[1] || 'jpg';
    const path = `${folder}/${filename || Date.now()}.${ext}`;

    const { data, error } = await supabase.storage
      .from('photos')
      .upload(path, buffer, {
        contentType: `image/${ext}`,
        upsert: true
      });

    if (error) return res.status(400).json({ error: error.message });

    // Get public URL
    const { data: urlData } = supabase.storage.from('photos').getPublicUrl(path);
    
    return res.json({ url: urlData.publicUrl, path });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
};
