function project_position(scene, point, model)
    p4d = to_ndim(Vec4f0, to_ndim(Vec3f0, point, 0f0), 1f0)
    clip = scene.camera.projectionview[] * model * p4d
    p = (clip / clip[4])[Vec(1, 2)]
    (p .+ 1) ./ 2
end

project_scale(scene::Scene, s::Number) = project_scale(scene, Vec2f0(s))

function project_scale(scene::Scene, s)
    p4d = to_ndim(Vec4f0, s, 0f0)
    p = (scene.camera.projectionview[] * p4d)[Vec(1, 2)] ./ 2f0
end

const marker_translation_table = Dict(
    '■' => GR.MARKERTYPE_SOLID_SQUARE,
    '★' => GR.MARKERTYPE_SOLID_STAR,
    '◆' => GR.MARKERTYPE_SOLID_DIAMOND,
    '⬢' => GR.MARKERTYPE_HEXAGON,
    '✚' => GR.MARKERTYPE_SOLID_PLUS,
    '❌' => GR.MARKERTYPE_DIAGONAL_CROSS,
    '▲' => GR.MARKERTYPE_SOLID_TRI_UP,
    '▼' => GR.MARKERTYPE_SOLID_TRI_DOWN,
    '◀' => GR.MARKERTYPE_SOLID_TRI_LEFT,
    '▶' => GR.MARKERTYPE_SOLID_TRI_RIGHT,
    '⬟' => GR.MARKERTYPE_PENTAGON,
    '⯄' => GR.MARKERTYPE_OCTAGON,
    '✦' => GR.MARKERTYPE_STAR_4,
    '🟋' => GR.MARKERTYPE_STAR_6,
    '✷' => GR.MARKERTYPE_STAR_8,
    '┃' => GR.MARKERTYPE_VLINE,
    '━' => GR.MARKERTYPE_HLINE,
    '+' => GR.MARKERTYPE_PLUS,
    'x' => GR.MARKERTYPE_DIAGONAL_CROSS,
    '●' => GR.MARKERTYPE_SOLID_CIRCLE
)
