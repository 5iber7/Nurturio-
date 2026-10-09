// Original Nurturio glTF assets. Run with Node; no editor, network or paid assets.
import fs from "node:fs";
const out = "apps/mobile/assets/models";
fs.mkdirSync(out, { recursive: true });
const colors = {
  grass: "#8baf78",
  soil: "#795a40",
  wood: "#ba8e63",
  trim: "#704e34",
  leaf: "#426c44",
  lightLeaf: "#719958",
  gold: "#dfb654",
  black: "#28322b",
  white: "#f4f0de",
  red: "#bc5141",
  roof: "#708374",
  skin: "#e2b591",
  cloth: "#427366",
  denim: "#405e6b",
  stone: "#b4b8a7",
  water: "#8cbfc0",
  glass: "#5b7556",
  cream: "#dbc79c",
};
const srgbToLinear = (v) =>
  v <= 0.04045 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4;
const qz = (a) => [0, 0, Math.sin(a / 2), Math.cos(a / 2)];
const qy = (a) => [0, Math.sin(a / 2), 0, Math.cos(a / 2)];
class Scene {
  constructor() {
    this.doc = {
      asset: { version: "2.0", generator: "Nurturio original scene generator" },
      scene: 0,
      scenes: [{ nodes: [] }],
      nodes: [],
      meshes: [],
      materials: [],
      accessors: [],
      bufferViews: [],
      animations: [],
    };
    this.parts = [];
    this.bytes = 0;
    this.cache = new Map();
    this.mats = new Map();
    this.channels = [];
    this.samplers = [];
  }
  material(name) {
    if (this.mats.has(name)) return this.mats.get(name);
    const hex = colors[name] ?? name;
    const rgb = [1, 3, 5].map((i) =>
      srgbToLinear(parseInt(hex.slice(i, i + 2), 16) / 255),
    );
    const id = this.doc.materials.length;
    this.doc.materials.push({
      name,
      pbrMetallicRoughness: {
        baseColorFactor: [...rgb, 1],
        metallicFactor: name === "glass" ? 0.12 : 0,
        roughnessFactor: name === "water" ? 0.3 : name === "glass" ? 0.2 : 0.78,
      },
      doubleSided: true,
    });
    this.mats.set(name, id);
    return id;
  }
  accessor(array, type, target) {
    const bytes = Buffer.from(array.buffer);
    const padding = (4 - (this.bytes % 4)) % 4;
    if (padding) {
      this.parts.push(Buffer.alloc(padding));
      this.bytes += padding;
    }
    const offset = this.bytes;
    this.parts.push(bytes);
    this.bytes += bytes.length;
    const v = this.doc.bufferViews.length;
    this.doc.bufferViews.push({
      buffer: 0,
      byteOffset: offset,
      byteLength: bytes.length,
      ...(target ? { target } : {}),
    });
    const count = array.length / { VEC3: 3, VEC4: 4, SCALAR: 1 }[type];
    const a = {
      bufferView: v,
      componentType: array instanceof Uint16Array ? 5123 : 5126,
      count,
      type,
    };
    if (type === "VEC3" || type === "SCALAR") {
      const n = type === "VEC3" ? 3 : 1;
      a.min = Array.from({ length: n }, (_, k) =>
        Math.min(...Array.from(array).filter((_, j) => j % n === k)),
      );
      a.max = Array.from({ length: n }, (_, k) =>
        Math.max(...Array.from(array).filter((_, j) => j % n === k)),
      );
    }
    this.doc.accessors.push(a);
    return this.doc.accessors.length - 1;
  }
  geometry(type, material) {
    const key = type + material;
    if (this.cache.has(key)) return this.cache.get(key);
    const p = [],
      n = [],
      ix = [];
    const face = (verts) => {
      const a = verts[0],
        b = verts[1],
        c = verts[2],
        u = b.map((x, i) => x - a[i]),
        v = c.map((x, i) => x - a[i]);
      let normal = [
        u[1] * v[2] - u[2] * v[1],
        u[2] * v[0] - u[0] * v[2],
        u[0] * v[1] - u[1] * v[0],
      ];
      const l = Math.hypot(...normal);
      normal = normal.map((x) => x / l);
      const s = p.length / 3;
      for (const pt of verts) {
        p.push(...pt);
        n.push(...normal);
      }
      for (let i = 1; i < verts.length - 1; i++) ix.push(s, s + i, s + i + 1);
    };
    if (type === "box") {
      for (const f of [
        [
          [0, 1, 2, 3],
          [4, 7, 6, 5],
          [0, 4, 5, 1],
          [3, 2, 6, 7],
          [1, 5, 6, 2],
          [0, 3, 7, 4],
        ],
      ]) {
        const pts = [
          [-0.5, -0.5, 0.5],
          [0.5, -0.5, 0.5],
          [0.5, 0.5, 0.5],
          [-0.5, 0.5, 0.5],
          [-0.5, -0.5, -0.5],
          [0.5, -0.5, -0.5],
          [0.5, 0.5, -0.5],
          [-0.5, 0.5, -0.5],
        ];
        for (const indices of f) face(indices.map((i) => pts[i]));
      }
    } else if (type === "roof") {
      const pts = [
        [-0.5, 0, 0.5],
        [0.5, 0, 0.5],
        [0, 0.5, 0.5],
        [-0.5, 0, -0.5],
        [0.5, 0, -0.5],
        [0, 0.5, -0.5],
      ];
      for (const f of [
        [0, 1, 2],
        [3, 5, 4],
        [0, 2, 5, 3],
        [2, 1, 4, 5],
        [0, 3, 4, 1],
      ])
        face(f.map((i) => pts[i]));
    } else if (type === "sphere") {
      const rows = 12,
        cols = 20;
      for (let y = 0; y <= rows; y++) {
        const phi = (Math.PI * y) / rows;
        for (let x = 0; x <= cols; x++) {
          const theta = (2 * Math.PI * x) / cols;
          const pt = [
            Math.sin(phi) * Math.cos(theta),
            Math.cos(phi),
            Math.sin(phi) * Math.sin(theta),
          ];
          p.push(...pt);
          n.push(...pt);
        }
      }
      for (let y = 0; y < rows; y++)
        for (let x = 0; x < cols; x++) {
          const a = y * (cols + 1) + x,
            b = a + cols + 1;
          if (y > 0) ix.push(a, a + 1, b);
          if (y < rows - 1) ix.push(a + 1, b + 1, b);
        }
    } else {
      const steps = 24,
        top = type === "cone" ? 0 : 1;
      for (let i = 0; i <= steps; i++) {
        const a = (i / steps) * Math.PI * 2,
          co = Math.cos(a),
          si = Math.sin(a);
        for (const [r, y] of [
          [1, -0.5],
          [top, 0.5],
        ]) {
          p.push(co * r, y, si * r);
          const norm = [co, type === "cone" ? 1 : 0, si],
            len = Math.hypot(...norm);
          n.push(...norm.map((x) => x / len));
        }
      }
      for (let i = 0; i < steps; i++) {
        const a = i * 2;
        ix.push(a, a + 1, a + 2, a + 1, a + 3, a + 2);
      }
      for (const [y, r, sign] of [
        [-0.5, 1, -1],
        [0.5, top, 1],
      ]) {
        if (r === 0) continue;
        const start = p.length / 3;
        p.push(0, y, 0);
        n.push(0, sign, 0);
        for (let i = 0; i <= steps; i++) {
          const a = (i / steps) * Math.PI * 2;
          p.push(Math.cos(a) * r, y, Math.sin(a) * r);
          n.push(0, sign, 0);
        }
        for (let i = 0; i < steps; i++)
          ix.push(
            start,
            start + i + (sign > 0 ? 2 : 1),
            start + i + (sign > 0 ? 1 : 2),
          );
      }
    }
    const mesh = this.doc.meshes.length;
    this.doc.meshes.push({
      primitives: [
        {
          attributes: {
            POSITION: this.accessor(new Float32Array(p), "VEC3", 34962),
            NORMAL: this.accessor(new Float32Array(n), "VEC3", 34962),
          },
          indices: this.accessor(new Uint16Array(ix), "SCALAR", 34963),
          material: this.material(material),
        },
      ],
    });
    this.cache.set(key, mesh);
    return mesh;
  }
  group(name, at = [0, 0, 0], parent) {
    const id = this.doc.nodes.length;
    this.doc.nodes.push({ name, translation: at, children: [] });
    if (parent === undefined) this.doc.scenes[0].nodes.push(id);
    else this.doc.nodes[parent].children.push(id);
    return id;
  }
  shape(type, mat, at, scale, parent, rotation) {
    const id = this.group(`${mat} ${type}`, at, parent);
    Object.assign(this.doc.nodes[id], {
      mesh: this.geometry(type, mat),
      scale,
      ...(rotation ? { rotation } : {}),
    });
    return id;
  }
  animate(id, path, frames) {
    const input = this.accessor(new Float32Array([0, 1, 2, 3, 4]), "SCALAR");
    const output = this.accessor(
      new Float32Array(frames.flat()),
      path === "rotation" ? "VEC4" : "VEC3",
    );
    const s = this.samplers.length;
    this.samplers.push({ input, output, interpolation: "LINEAR" });
    this.channels.push({ sampler: s, target: { node: id, path } });
  }
  save(name) {
    for (const n of this.doc.nodes) if (!n.children.length) delete n.children;
    if (!this.channels.length) delete this.doc.animations;
    if (this.channels.length)
      this.doc.animations.push({
        name: "Nature loop",
        samplers: this.samplers,
        channels: this.channels,
      });
    const pad = (4 - (this.bytes % 4)) % 4;
    if (pad) {
      this.parts.push(Buffer.alloc(pad));
      this.bytes += pad;
    }
    this.doc.buffers = [{ byteLength: this.bytes }];
    let json = Buffer.from(JSON.stringify(this.doc));
    const extra = (4 - (json.length % 4)) % 4;
    json = Buffer.concat([json, Buffer.alloc(extra, 32)]);
    const binary = Buffer.concat(this.parts);
    const header = Buffer.alloc(12),
      jh = Buffer.alloc(8),
      bh = Buffer.alloc(8);
    header.writeUInt32LE(0x46546c67, 0);
    header.writeUInt32LE(2, 4);
    header.writeUInt32LE(12 + 8 + json.length + 8 + binary.length, 8);
    jh.writeUInt32LE(json.length, 0);
    jh.writeUInt32LE(0x4e4f534a, 4);
    bh.writeUInt32LE(binary.length, 0);
    bh.writeUInt32LE(0x004e4942, 4);
    fs.writeFileSync(
      `${out}/${name}.glb`,
      Buffer.concat([header, jh, json, bh, binary]),
    );
    return {
      id: name,
      nodes: this.doc.nodes.length,
      triangles: this.doc.meshes.reduce(
        (sum, m) => sum + this.doc.accessors[m.primitives[0].indices].count / 3,
        0,
      ),
    };
  }
}
function ground(s, r = 2.6) {
  s.shape("cylinder", "soil", [0, -0.17, 0], [r, 0.32, r]);
  s.shape("cylinder", "grass", [0, 0.015, 0], [r, 0.065, r]);
  for (let i = 0; i < 14; i++) {
    const a = i * 0.73,
      radius = r * (0.65 + (i % 3) * 0.09);
    s.shape(
      "sphere",
      i % 2 ? "lightLeaf" : "stone",
      [Math.cos(a) * radius, 0.06, Math.sin(a) * radius],
      [0.14, 0.06, 0.1],
    );
  }
  for (let i = 0; i < 7; i++)
    s.shape(
      "sphere",
      "stone",
      [-0.8 + i * 0.24, 0.065, 1.1 - i * 0.14],
      [0.19, 0.045, 0.16],
    );
}
function bee(s, at, size = 0.8) {
  const root = s.group("Flying honeybee", at);
  s.doc.nodes[root].scale = [size, size, size];
  s.shape("sphere", "gold", [0, 0, 0], [0.25, 0.16, 0.17], root);
  for (const x of [-0.11, 0.04, 0.16])
    s.shape("sphere", "black", [x, 0, 0], [0.035, 0.162, 0.171], root);
  s.shape("sphere", "gold", [-0.24, 0.03, 0], [0.15, 0.15, 0.15], root);
  for (const z of [-0.09, 0.09]) {
    s.shape("sphere", "black", [-0.33, 0.08, z], [0.035, 0.04, 0.035], root);
    s.shape("sphere", "white", [-0.352, 0.096, z], [0.009, 0.011, 0.01], root);
    s.shape(
      "cylinder",
      "black",
      [-0.23, 0.22, z],
      [0.009, 0.13, 0.009],
      root,
      qz(-0.3),
    );
    s.shape("sphere", "black", [-0.25, 0.28, z], [0.018, 0.018, 0.018], root);
    const wing = s.group("Flapping wing", [0, 0.13, z * 0.8], root);
    s.shape(
      "sphere",
      "white",
      [0.025, 0.045, z > 0 ? 0.2 : -0.2],
      [0.19, 0.032, 0.2],
      wing,
    );
    s.animate(
      wing,
      "rotation",
      [0, 1, 2, 3, 4].map((i) => qy((i % 2 ? 0.45 : -0.4) * (z > 0 ? 1 : -1))),
    );
  }
  s.animate(
    root,
    "translation",
    [0, 1, 2, 3, 4].map((i) => [
      at[0] + Math.sin((i * Math.PI) / 2) * 0.12,
      at[1] + Math.sin(i * Math.PI) * 0.05 + (i % 2) * 0.1,
      at[2] + Math.sin((i * Math.PI) / 2) * 0.06,
    ]),
  );
  return root;
}
function farmer(s, at, scale = 0.85) {
  const root = s.group("Nurturio farmer guide", at);
  s.doc.nodes[root].scale = [scale, scale, scale];
  for (const x of [-0.12, 0.12]) {
    s.shape("cylinder", "denim", [x, 0.34, 0], [0.095, 0.48, 0.1], root);
    s.shape("sphere", "trim", [x, 0.12, 0.05], [0.115, 0.12, 0.17], root);
  }
  s.shape("sphere", "cloth", [0, 0.86, 0], [0.29, 0.36, 0.2], root);
  s.shape("box", "wood", [0, 0.95, -0.2], [0.32, 0.4, 0.15], root);
  s.shape("sphere", "trim", [0, 1.35, -0.04], [0.225, 0.26, 0.21], root);
  s.shape("sphere", "skin", [0, 1.33, 0.045], [0.2, 0.24, 0.2], root);
  for (const x of [-0.068, 0.068]) {
    s.shape("sphere", "black", [x, 1.36, 0.235], [0.018, 0.022, 0.016], root);
    s.shape(
      "sphere",
      "white",
      [x - 0.005, 1.368, 0.247],
      [0.004, 0.005, 0.004],
      root,
    );
  }
  s.shape("sphere", "skin", [0, 1.3, 0.251], [0.038, 0.036, 0.04], root);
  s.shape("cylinder", "cream", [0, 1.58, 0], [0.35, 0.032, 0.32], root);
  s.shape("cylinder", "cream", [0, 1.67, 0], [0.205, 0.15, 0.2], root);
  s.shape("cylinder", "gold", [0, 1.61, 0], [0.209, 0.035, 0.204], root);
  s.shape(
    "cylinder",
    "cloth",
    [-0.32, 0.94, 0],
    [0.1, 0.33, 0.1],
    root,
    qz(-0.35),
  );
  s.shape("sphere", "skin", [-0.38, 0.73, 0.02], [0.083, 0.1, 0.075], root);
  const arm = s.group("Waving arm", [0.23, 1.04, 0], root);
  s.shape(
    "cylinder",
    "cloth",
    [0.1, 0, 0],
    [0.095, 0.25, 0.095],
    arm,
    qz(Math.PI / 2),
  );
  s.shape(
    "cylinder",
    "skin",
    [0.25, 0, 0],
    [0.065, 0.15, 0.065],
    arm,
    qz(Math.PI / 2),
  );
  s.shape("sphere", "skin", [0.34, 0, 0], [0.08, 0.09, 0.065], arm);
  s.animate(arm, "rotation", [0.4, 0.75, 0.5, 0.75, 0.4].map(qz));
  return root;
}
function hive(s, x, z) {
  const root = s.group("Wooden beehive", [x, 0, z]);
  for (const a of [-0.29, 0.29])
    s.shape("box", "trim", [a, 0.19, 0], [0.07, 0.35, 0.55], root);
  s.shape("box", "wood", [0, 0.61, 0], [0.85, 0.6, 0.65], root);
  for (let y = 0.39; y < 0.9; y += 0.12)
    s.shape("box", "cream", [0, y, 0.335], [0.79, 0.022, 0.022], root);
  s.shape("box", "trim", [0, 0.96, 0], [0.99, 0.11, 0.79], root);
  s.shape("box", "black", [0, 0.4, 0.338], [0.32, 0.04, 0.03], root);
  s.shape("box", "trim", [0, 0.345, 0.43], [0.53, 0.06, 0.23], root);
  s.shape("box", "gold", [0.2, 0.82, 0.345], [0.08, 0.07, 0.025], root);
}
function tree(s, x, z, scale = 1) {
  const root = s.group("Olive tree", [x, 0, z]);
  s.doc.nodes[root].scale = [scale, scale, scale];
  s.shape("cylinder", "trim", [0, 0.72, 0], [0.11, 1.4, 0.11], root);
  for (let i = 0; i < 5; i++) {
    const a = i * 2.4;
    s.shape(
      "sphere",
      i % 2 ? "leaf" : "lightLeaf",
      [Math.cos(a) * 0.31, 1.3 + (i % 3) * 0.19, Math.sin(a) * 0.3],
      [0.46, 0.45, 0.44],
      root,
    );
    for (let j = 0; j < 3; j++)
      s.shape(
        "sphere",
        "black",
        [
          Math.cos(a) * 0.31 + (j - 1) * 0.13,
          1.2 + (i % 3) * 0.18,
          Math.sin(a) * 0.3 + 0.39,
        ],
        [0.033, 0.045, 0.033],
        root,
      );
  }
}
function hen(s, x, z, size = 1) {
  const root = s.group("Chicken", [x, 0.13, z]);
  s.doc.nodes[root].scale = [size, size, size];
  s.shape("sphere", "white", [0, 0.33, 0], [0.3, 0.27, 0.34], root);
  s.shape("sphere", "cream", [-0.25, 0.33, -0.03], [0.07, 0.15, 0.22], root);
  s.shape("sphere", "cream", [0.25, 0.33, -0.03], [0.07, 0.15, 0.22], root);
  s.shape("sphere", "white", [0, 0.61, 0.23], [0.19, 0.2, 0.18], root);
  s.shape("cone", "gold", [0, 0.57, 0.45], [0.073, 0.16, 0.065], root, [
    Math.sin(Math.PI / 4),
    0,
    0,
    Math.cos(Math.PI / 4),
  ]);
  for (const x of [-0.14, 0.14])
    s.shape("sphere", "black", [x, 0.64, 0.32], [0.025, 0.03, 0.025], root);
  for (let i = 0; i < 3; i++)
    s.shape(
      "sphere",
      "red",
      [(i - 1) * 0.055, 0.8, 0.2],
      [0.049, 0.065, 0.055],
      root,
    );
  s.shape("sphere", "red", [0, 0.47, 0.37], [0.045, 0.065, 0.04], root);
  for (const x of [-0.09, 0.09]) {
    s.shape("cylinder", "gold", [x, 0.09, 0], [0.026, 0.22, 0.026], root);
    for (let i = 0; i < 3; i++)
      s.shape(
        "sphere",
        "gold",
        [x + (i - 1) * 0.035, 0.006, 0.09],
        [0.024, 0.018, 0.1],
        root,
      );
  }
  s.shape("sphere", "white", [0, 0.46, -0.29], [0.16, 0.18, 0.1], root);
  s.animate(root, "rotation", [0, 0.15, -0.1, 0.12, 0].map(qy));
  return root;
}
function coop(s, x, z) {
  const root = s.group("Timber coop", [x, 0, z]);
  for (const a of [-0.48, 0.48])
    s.shape("box", "trim", [a, 0.23, 0], [0.08, 0.45, 0.8], root);
  s.shape("box", "wood", [0, 0.83, 0], [1.15, 1, 0.92], root);
  s.shape("roof", "roof", [0, 1.32, 0], [1.4, 0.8, 1.18], root);
  s.shape("box", "trim", [0, 0.73, 0.47], [0.43, 0.69, 0.035], root);
  s.shape("box", "cream", [0.37, 1.06, 0.48], [0.25, 0.25, 0.04], root);
  s.shape("box", "black", [0.37, 1.06, 0.505], [0.18, 0.18, 0.01], root);
  s.shape("box", "cream", [0.37, 1.06, 0.515], [0.018, 0.2, 0.012], root);
  s.shape("box", "wood", [0, 0.25, 0.8], [0.5, 0.07, 0.7], root, [
    -Math.sin(0.22),
    0,
    0,
    Math.cos(0.22),
  ]);
}
function plant(s, x, z, id = "tomato", growth = 1) {
  const root = s.group(`${id} raised bed`, [x, 0, z]);
  s.shape("box", "wood", [0, 0.16, 0], [0.85, 0.27, 0.66], root);
  s.shape("box", "soil", [0, 0.31, 0], [0.76, 0.035, 0.58], root);
  for (const a of [-0.4, 0.4])
    s.shape("box", "trim", [a, 0.18, 0], [0.04, 0.28, 0.7], root);
  const stem = s.group("Growing plant", [0, 0.32, 0], root);
  s.doc.nodes[stem].scale = [growth, growth, growth];
  const h = id === "sunflower" ? 0.95 : id === "carrot" ? 0.27 : 0.64;
  s.shape("cylinder", "leaf", [0, h / 2, 0], [0.025, h, 0.025], stem);
  for (let i = 0; i < 5; i++) {
    const side = i % 2 ? 1 : -1;
    s.shape(
      "sphere",
      i % 2 ? "lightLeaf" : "leaf",
      [side * 0.15, 0.12 + i * h * 0.12, ((i % 3) - 1) * 0.07],
      [0.17, 0.045, 0.082],
      stem,
      qz(side * 0.35),
    );
  }
  if (["tomato", "strawberry"].includes(id))
    for (let i = 0; i < 4; i++)
      s.shape(
        "sphere",
        "red",
        [((i % 2) - 0.5) * 0.32, 0.33 + Math.floor(i / 2) * 0.14, 0.13],
        [0.085, 0.09, 0.075],
        stem,
      );
  if (id === "carrot")
    s.shape("cone", "gold", [0, -0.035, 0], [0.1, 0.3, 0.1], stem, qz(Math.PI));
  if (id === "lettuce")
    for (let i = 0; i < 7; i++) {
      const a = i * 2.4;
      s.shape(
        "sphere",
        "lightLeaf",
        [Math.cos(a) * 0.14, 0.18 + (i % 3) * 0.06, Math.sin(a) * 0.13],
        [0.14, 0.13, 0.15],
        stem,
      );
    }
  if (["sunflower", "marigold"].includes(id)) {
    const y = h;
    for (let i = 0; i < 10; i++) {
      const a = (i * Math.PI) / 5;
      s.shape(
        "sphere",
        "gold",
        [Math.cos(a) * 0.14, y + Math.sin(a) * 0.14, 0],
        [0.09, 0.075, 0.035],
        stem,
      );
    }
    s.shape("sphere", "soil", [0, y, 0.015], [0.104, 0.104, 0.05], stem);
  }
  return root;
}
function fence(s, x, z) {
  const root = s.group("Fence", [x, 0, z]);
  for (let i = 0; i < 4; i++)
    s.shape(
      "box",
      "cream",
      [(i - 1.5) * 0.3, 0.32, 0],
      [0.065, 0.62, 0.065],
      root,
    );
  for (const y of [0.24, 0.47])
    s.shape("box", "wood", [0, y, 0], [1.12, 0.06, 0.045], root);
}
const manifest = [];
for (const world of ["village", "honey", "olive", "chicken", "garden"]) {
  const s = new Scene();
  ground(s, world === "village" ? 3.35 : 2.35);
  if (world === "village") {
    hive(s, -1.48, -0.12);
    coop(s, 1.15, -1.05);
    tree(s, -1.4, -1.45, 0.85);
    tree(s, 1.9, 0.78, 0.9);
    plant(s, -0.6, 1.32, "tomato");
    plant(s, 0.46, 1.29, "sunflower");
    farmer(s, [0, 0, 0.1]);
    bee(s, [-1.5, 1.25, 0.67]);
    hen(s, 1.05, 0.2, 0.8);
    fence(s, 0.2, -2.2);
  } else if (world === "honey") {
    hive(s, -0.67, -0.3);
    hive(s, 0.7, -0.62);
    bee(s, [-0.1, 1.4, 1.1], 1.45);
    bee(s, [-1.3, 1.3, 0]);
    bee(s, [0.95, 1.32, 0.26]);
    plant(s, -1.25, 1, "sunflower");
    farmer(s, [1.4, 0, 0.73], 0.7);
    tree(s, -1.5, -1.2, 0.6);
  } else if (world === "olive") {
    tree(s, -0.85, -0.5);
    tree(s, 0.85, -0.75, 0.86);
    farmer(s, [-0.45, 0, 0.93]);
    s.shape("box", "wood", [0.85, 0.2, 0.9], [0.8, 0.4, 0.62]);
    for (let i = 0; i < 8; i++)
      s.shape(
        "sphere",
        "black",
        [
          0.58 + (i % 3) * 0.23,
          0.47 + Math.floor(i / 3) * 0.06,
          0.68 + (i % 2) * 0.26,
        ],
        [0.1, 0.13, 0.1],
      );
    s.shape("cylinder", "glass", [1.1, 0.82, 0.99], [0.08, 0.43, 0.08]);
    s.shape("cylinder", "gold", [1.1, 1.075, 0.99], [0.04, 0.1, 0.04]);
  } else if (world === "chicken") {
    coop(s, 0, -0.6);
    hen(s, -0.7, 0.71, 1.2);
    hen(s, 0.58, 0.57, 0.95);
    hen(s, 1.0, 0.2, 0.5);
    fence(s, -1.03, -1.38);
    s.shape("cylinder", "water", [1.2, 0.12, 0.82], [0.26, 0.08, 0.26]);
    farmer(s, [-1.35, 0, -0.1], 0.7);
  } else {
    plant(s, -0.7, 0.7, "tomato");
    plant(s, 0.6, 0.8, "sunflower");
    plant(s, -0.7, -0.4, "lettuce");
    plant(s, 0.65, -0.4, "marigold");
    farmer(s, [1.5, 0, 0.0], 0.7);
    tree(s, -1.3, -1.3, 0.7);
    bee(s, [0.52, 1.48, 1.0], 0.8);
  }
  manifest.push(s.save(world));
}
for (const id of [
  "tomato",
  "sunflower",
  "mint",
  "carrot",
  "strawberry",
  "marigold",
  "lettuce",
  "basil",
]) {
  const s = new Scene();
  plant(s, 0, 0, id);
  manifest.push(s.save(`plant-${id}`));
}
for (const [id, growth] of [
  ["sprout", 0.24],
  ["leafy", 0.65],
]) {
  const s = new Scene();
  plant(s, 0, 0, "basil", growth);
  manifest.push(s.save(id));
}
const buzz = new Scene();
bee(buzz, [0, 0.25, 0], 2.2);
manifest.push(buzz.save("buzz"));
fs.writeFileSync(
  `${out}/manifest.json`,
  JSON.stringify(
    {
      version: 1,
      license: "Original Nurturio models; repository owner controls licensing.",
      models: manifest,
    },
    null,
    2,
  ) + "\n",
);
console.log(`Built ${manifest.length} original animated glTF scenes.`);
