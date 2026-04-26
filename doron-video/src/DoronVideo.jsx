import {
  AbsoluteFill,
  useCurrentFrame,
  useVideoConfig,
  interpolate,
  spring,
  Easing,
  Sequence,
} from "remotion";

// ─── Palette Doron ────────────────────────────────────────────────────────────
const VIOLET = "#8A2BE2";
const VIOLET_LIGHT = "#A855F7";
const NAVY = "#0F0F1A";
const NAVY2 = "#1A1A2E";
const WHITE = "#FFFFFF";
const GREY = "rgba(255,255,255,0.6)";
const GOLD = "#F59E0B";

// ─── Helpers ──────────────────────────────────────────────────────────────────
const easeOut = Easing.out(Easing.cubic);

function fadeIn(frame, start = 0, duration = 20) {
  return interpolate(frame, [start, start + duration], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: easeOut,
  });
}

function slideUp(frame, start = 0, duration = 25, distance = 60) {
  const t = interpolate(frame, [start, start + duration], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: easeOut,
  });
  return `translateY(${(1 - t) * distance}px)`;
}

function scaleIn(frame, start = 0, duration = 20, fps = 30) {
  return spring({ frame: frame - start, fps, config: { damping: 14, stiffness: 120 } });
}

// ─── Composants réutilisables ─────────────────────────────────────────────────

const GradientBg = () => (
  <AbsoluteFill
    style={{
      background: `linear-gradient(160deg, ${NAVY} 0%, ${NAVY2} 50%, #16013a 100%)`,
    }}
  />
);

const Particles = ({ frame }) => {
  const dots = Array.from({ length: 18 }, (_, i) => ({
    x: ((i * 137.5) % 100),
    y: ((i * 83.7) % 100),
    size: 2 + (i % 3),
    delay: i * 8,
    opacity: 0.08 + (i % 4) * 0.04,
  }));
  return (
    <AbsoluteFill style={{ pointerEvents: "none" }}>
      {dots.map((d, i) => (
        <div
          key={i}
          style={{
            position: "absolute",
            left: `${d.x}%`,
            top: `${d.y}%`,
            width: d.size,
            height: d.size,
            borderRadius: "50%",
            background: VIOLET_LIGHT,
            opacity: d.opacity + Math.sin((frame + d.delay) / 40) * 0.04,
          }}
        />
      ))}
    </AbsoluteFill>
  );
};

const PhoneMockup = ({ children, frame, startFrame = 0, scale = 1 }) => {
  const s = scaleIn(frame, startFrame, 25, 30);
  const opacity = fadeIn(frame, startFrame, 20);
  return (
    <div
      style={{
        transform: `scale(${s * scale})`,
        opacity,
        width: 320,
        height: 640,
        borderRadius: 44,
        background: NAVY,
        border: `2px solid rgba(255,255,255,0.12)`,
        boxShadow: `0 40px 120px rgba(0,0,0,0.7), 0 0 0 1px rgba(255,255,255,0.05), inset 0 1px 0 rgba(255,255,255,0.1)`,
        overflow: "hidden",
        position: "relative",
      }}
    >
      {/* Notch */}
      <div style={{
        position: "absolute",
        top: 12,
        left: "50%",
        transform: "translateX(-50%)",
        width: 100,
        height: 28,
        background: "#000",
        borderRadius: 20,
        zIndex: 10,
      }} />
      {/* Contenu */}
      <div style={{ position: "absolute", inset: 0, paddingTop: 50 }}>
        {children}
      </div>
    </div>
  );
};

const Tag = ({ children, color = VIOLET }) => (
  <div style={{
    display: "inline-flex",
    alignItems: "center",
    padding: "6px 16px",
    borderRadius: 20,
    background: `${color}22`,
    border: `1px solid ${color}44`,
    color: color,
    fontSize: 22,
    fontWeight: 700,
    letterSpacing: 1,
    fontFamily: "sans-serif",
  }}>
    {children}
  </div>
);

const FeatureLine = ({ icon, text, frame, delay = 0 }) => {
  const op = fadeIn(frame, delay, 18);
  const tr = slideUp(frame, delay, 22, 30);
  return (
    <div style={{
      display: "flex", alignItems: "center", gap: 20,
      opacity: op, transform: tr, marginBottom: 28,
    }}>
      <div style={{
        width: 56, height: 56, borderRadius: 16,
        background: `${VIOLET}22`, border: `1px solid ${VIOLET}44`,
        display: "flex", alignItems: "center", justifyContent: "center",
        fontSize: 28, flexShrink: 0,
      }}>{icon}</div>
      <span style={{
        fontFamily: "sans-serif", fontSize: 32, fontWeight: 600,
        color: WHITE, lineHeight: 1.3,
      }}>{text}</span>
    </div>
  );
};

// ─── SCÈNE 0 : Intro Logo (frames 0-90 = 3s) ─────────────────────────────────
const SceneIntro = ({ frame }) => {
  const logoScale = scaleIn(frame, 10, 30, 30);
  const logoOp = fadeIn(frame, 10, 20);
  const taglineOp = fadeIn(frame, 35, 25);
  const taglineTr = slideUp(frame, 35, 30, 40);

  // Glow pulsant
  const glow = 0.4 + Math.sin(frame / 15) * 0.15;

  return (
    <AbsoluteFill style={{ alignItems: "center", justifyContent: "center", flexDirection: "column" }}>
      <GradientBg />
      <Particles frame={frame} />

      {/* Cercle glow */}
      <div style={{
        position: "absolute",
        width: 400, height: 400, borderRadius: "50%",
        background: `radial-gradient(circle, ${VIOLET}${Math.round(glow * 255).toString(16).padStart(2, "0")} 0%, transparent 70%)`,
        transform: `scale(${logoScale})`,
      }} />

      {/* Logo texte */}
      <div style={{
        transform: `scale(${logoScale})`,
        opacity: logoOp,
        fontFamily: "sans-serif",
        fontSize: 110,
        fontWeight: 900,
        color: WHITE,
        letterSpacing: -3,
        textShadow: `0 0 60px ${VIOLET}88`,
      }}>
        doron
      </div>

      {/* Point violet */}
      <div style={{
        width: 18, height: 18, borderRadius: "50%",
        background: VIOLET,
        transform: `scale(${logoScale})`,
        opacity: logoOp,
        marginTop: -20,
        boxShadow: `0 0 30px ${VIOLET}`,
      }} />

      {/* Tagline */}
      <div style={{
        opacity: taglineOp,
        transform: taglineTr,
        marginTop: 40,
        fontFamily: "sans-serif",
        fontSize: 38,
        fontWeight: 300,
        color: "rgba(255,255,255,0.75)",
        letterSpacing: 2,
        textAlign: "center",
      }}>
        Le cadeau, réinventé.
      </div>
    </AbsoluteFill>
  );
};

// ─── SCÈNE 1 : Wishlist & Inspiration (frames 90-450 = 12s) ──────────────────
const SceneWishlist = ({ frame }) => {
  const localFrame = frame - 90;

  const titleOp = fadeIn(localFrame, 5, 20);
  const titleTr = slideUp(localFrame, 5, 25, 50);
  const phoneOp = fadeIn(localFrame, 20, 25);
  const phoneS = scaleIn(localFrame, 20, 30, 30);

  // Simulation du scroll dans le téléphone
  const scrollY = interpolate(localFrame, [80, 280], [0, -200], {
    extrapolateLeft: "clamp", extrapolateRight: "clamp", easing: easeOut,
  });

  const subtitleOp = fadeIn(localFrame, 40, 20);

  // Produits mockup
  const products = [
    { emoji: "📚", name: "Assouline Book", price: "95€", brand: "Assouline" },
    { emoji: "🎮", name: "PlayStation 5", price: "549€", brand: "Sony" },
    { emoji: "👜", name: "Sac Le Pliage", price: "120€", brand: "Longchamp" },
    { emoji: "💎", name: "Collier Diamant", price: "890€", brand: "Tiffany" },
    { emoji: "🎧", name: "AirPods Pro", price: "279€", brand: "Apple" },
    { emoji: "🌹", name: "Bougie Figuier", price: "85€", brand: "Diptyque" },
  ];

  return (
    <AbsoluteFill style={{ alignItems: "center", justifyContent: "center", flexDirection: "column" }}>
      <GradientBg />
      <Particles frame={localFrame} />

      {/* titre section */}
      <div style={{
        position: "absolute", top: 120,
        opacity: titleOp, transform: titleTr,
        textAlign: "center", padding: "0 60px",
      }}>
        <Tag>✨ Inspiration</Tag>
        <div style={{
          fontFamily: "sans-serif", fontSize: 56, fontWeight: 800,
          color: WHITE, marginTop: 20, lineHeight: 1.15, letterSpacing: -1,
        }}>
          Des milliers de{"\n"}cadeaux triés pour toi
        </div>
        <div style={{
          fontFamily: "sans-serif", fontSize: 30, color: GREY,
          marginTop: 16, opacity: subtitleOp, fontWeight: 300,
        }}>
          Parcours, aime, sauvegarde.
        </div>
      </div>

      {/* Téléphone */}
      <div style={{
        position: "absolute", bottom: 80,
        transform: `scale(${phoneS})`,
        opacity: phoneOp,
      }}>
        <PhoneMockup frame={localFrame} startFrame={20} scale={1}>
          {/* Header */}
          <div style={{
            padding: "0 16px 12px",
            fontFamily: "sans-serif", fontSize: 20, fontWeight: 700,
            color: WHITE, borderBottom: "1px solid rgba(255,255,255,0.06)",
          }}>
            ✨ Inspiration
          </div>

          {/* Grille produits scrollable */}
          <div style={{
            display: "grid", gridTemplateColumns: "1fr 1fr",
            gap: 8, padding: "8px 12px",
            transform: `translateY(${scrollY}px)`,
            transition: "transform 0.1s",
          }}>
            {products.map((p, i) => {
              const cardOp = fadeIn(localFrame, 30 + i * 12, 15);
              const heartScale = localFrame > 150 + i * 30 ? scaleIn(localFrame, 150 + i * 30, 10, 30) : 1;
              return (
                <div key={i} style={{
                  background: "rgba(255,255,255,0.05)",
                  borderRadius: 16, overflow: "hidden",
                  border: "1px solid rgba(255,255,255,0.08)",
                  opacity: cardOp,
                }}>
                  {/* Image */}
                  <div style={{
                    height: 80, background: `linear-gradient(135deg, ${VIOLET}22, rgba(255,255,255,0.05))`,
                    display: "flex", alignItems: "center", justifyContent: "center",
                    fontSize: 36,
                  }}>
                    {p.emoji}
                    {/* Coeur animé */}
                    {localFrame > 170 + i * 25 && (
                      <div style={{
                        position: "absolute", top: 4, right: 4,
                        fontSize: 16,
                        transform: `scale(${heartScale})`,
                      }}>❤️</div>
                    )}
                  </div>
                  <div style={{ padding: "6px 8px" }}>
                    <div style={{ fontSize: 11, color: GREY, fontFamily: "sans-serif" }}>{p.brand}</div>
                    <div style={{ fontSize: 12, color: WHITE, fontWeight: 600, fontFamily: "sans-serif" }}>{p.name}</div>
                    <div style={{ fontSize: 13, color: VIOLET_LIGHT, fontWeight: 700, fontFamily: "sans-serif" }}>{p.price}</div>
                  </div>
                </div>
              );
            })}
          </div>
        </PhoneMockup>
      </div>
    </AbsoluteFill>
  );
};

// ─── SCÈNE 2 : Wishlists / Albums (frames 450-810 = 12s) ─────────────────────
const SceneAlbums = ({ frame }) => {
  const localFrame = frame - 450;
  const titleOp = fadeIn(localFrame, 5, 20);
  const titleTr = slideUp(localFrame, 5, 25, 50);
  const phoneS = scaleIn(localFrame, 20, 30, 30);

  const wishlists = [
    { emoji: "🎂", name: "Mon Anniversaire", count: 12, color: "#8A2BE2" },
    { emoji: "🎄", name: "Noël 2025", count: 8, color: "#10B981" },
    { emoji: "💍", name: "Mariage", count: 24, color: GOLD },
    { emoji: "👶", name: "Bébé", count: 16, color: "#F472B6" },
  ];

  return (
    <AbsoluteFill style={{ alignItems: "center", justifyContent: "center", flexDirection: "column" }}>
      <GradientBg />
      <Particles frame={localFrame} />

      <div style={{
        position: "absolute", top: 140,
        opacity: titleOp, transform: titleTr, textAlign: "center", padding: "0 60px",
      }}>
        <Tag color={GOLD}>🎁 Wishlists</Tag>
        <div style={{
          fontFamily: "sans-serif", fontSize: 54, fontWeight: 800,
          color: WHITE, marginTop: 20, lineHeight: 1.15,
        }}>
          Tes cadeaux,{"\n"}organisés par occasion
        </div>
      </div>

      <div style={{
        position: "absolute", bottom: 80,
        transform: `scale(${phoneS})`,
        opacity: fadeIn(localFrame, 20, 20),
      }}>
        <PhoneMockup frame={localFrame} startFrame={20}>
          <div style={{ padding: "0 14px" }}>
            <div style={{
              fontFamily: "sans-serif", fontSize: 18, fontWeight: 700,
              color: WHITE, marginBottom: 14,
            }}>Mes Albums 🎁</div>
            {wishlists.map((w, i) => {
              const op = fadeIn(localFrame, 30 + i * 18, 18);
              const tr = slideUp(localFrame, 30 + i * 18, 22, 30);
              return (
                <div key={i} style={{
                  display: "flex", alignItems: "center", gap: 12,
                  background: "rgba(255,255,255,0.05)",
                  border: `1px solid ${w.color}33`,
                  borderRadius: 14, padding: "10px 14px", marginBottom: 10,
                  opacity: op, transform: tr,
                }}>
                  <div style={{
                    width: 42, height: 42, borderRadius: 12,
                    background: `${w.color}22`,
                    display: "flex", alignItems: "center", justifyContent: "center",
                    fontSize: 22,
                  }}>{w.emoji}</div>
                  <div style={{ flex: 1 }}>
                    <div style={{ fontFamily: "sans-serif", fontSize: 14, fontWeight: 600, color: WHITE }}>{w.name}</div>
                    <div style={{ fontFamily: "sans-serif", fontSize: 11, color: GREY }}>{w.count} cadeaux</div>
                  </div>
                  <div style={{ fontSize: 16 }}>›</div>
                </div>
              );
            })}
          </div>
        </PhoneMockup>
      </div>
    </AbsoluteFill>
  );
};

// ─── SCÈNE 3 : Réseau social & Partage (frames 810-1170 = 12s) ───────────────
const SceneSocial = ({ frame }) => {
  const localFrame = frame - 810;
  const titleOp = fadeIn(localFrame, 5, 20);
  const titleTr = slideUp(localFrame, 5, 25, 50);

  return (
    <AbsoluteFill style={{ alignItems: "center", justifyContent: "center", flexDirection: "column" }}>
      <GradientBg />
      <Particles frame={localFrame} />

      <div style={{
        position: "absolute", top: 140,
        opacity: titleOp, transform: titleTr, textAlign: "center", padding: "0 60px",
      }}>
        <Tag color="#10B981">👥 Social</Tag>
        <div style={{
          fontFamily: "sans-serif", fontSize: 54, fontWeight: 800,
          color: WHITE, marginTop: 20, lineHeight: 1.15,
        }}>
          Partage,{"\n"}offre, surprise.
        </div>
      </div>

      {/* Features list */}
      <div style={{
        position: "absolute", bottom: 120,
        padding: "0 80px", width: "100%",
      }}>
        <FeatureLine frame={localFrame} delay={25} icon="👫" text="Ajoute tes amis & famille" />
        <FeatureLine frame={localFrame} delay={45} icon="🎁" text="Vois leurs wishlists en secret" />
        <FeatureLine frame={localFrame} delay={65} icon="💬" text="Chat et planifie ensemble" />
        <FeatureLine frame={localFrame} delay={85} icon="🤝" text="Wishlists collaboratives" />
      </div>
    </AbsoluteFill>
  );
};

// ─── SCÈNE 4 : Questionnaire IA (frames 1170-1440 = 9s) ──────────────────────
const SceneQuestionnaire = ({ frame }) => {
  const localFrame = frame - 1170;
  const titleOp = fadeIn(localFrame, 5, 20);
  const titleTr = slideUp(localFrame, 5, 25, 50);
  const phoneS = scaleIn(localFrame, 20, 30, 30);

  const questions = [
    { q: "Pour quelle occasion ?", a: "🎂 Anniversaire", delay: 30 },
    { q: "Quel budget ?", a: "💜 50€ - 100€", delay: 70 },
    { q: "Quel style ?", a: "✨ Luxe & Premium", delay: 110 },
  ];

  return (
    <AbsoluteFill style={{ alignItems: "center", justifyContent: "center", flexDirection: "column" }}>
      <GradientBg />
      <Particles frame={localFrame} />

      <div style={{
        position: "absolute", top: 140,
        opacity: titleOp, transform: titleTr, textAlign: "center", padding: "0 60px",
      }}>
        <Tag color="#A855F7">🤖 IA Cadeaux</Tag>
        <div style={{
          fontFamily: "sans-serif", fontSize: 50, fontWeight: 800,
          color: WHITE, marginTop: 20, lineHeight: 1.2,
        }}>
          Trouve le cadeau{"\n"}parfait en 3 clics
        </div>
      </div>

      <div style={{
        position: "absolute", bottom: 80,
        transform: `scale(${phoneS})`,
        opacity: fadeIn(localFrame, 20, 20),
      }}>
        <PhoneMockup frame={localFrame} startFrame={20}>
          <div style={{ padding: "0 16px" }}>
            {questions.map((item, i) => {
              const op = fadeIn(localFrame, item.delay, 18);
              const tr = slideUp(localFrame, item.delay, 22, 25);
              return (
                <div key={i} style={{ marginBottom: 16, opacity: op, transform: tr }}>
                  <div style={{ fontFamily: "sans-serif", fontSize: 12, color: GREY, marginBottom: 6 }}>{item.q}</div>
                  <div style={{
                    background: `${VIOLET}22`, border: `1px solid ${VIOLET}44`,
                    borderRadius: 12, padding: "10px 14px",
                    fontFamily: "sans-serif", fontSize: 15, fontWeight: 600, color: VIOLET_LIGHT,
                  }}>
                    {item.a}
                  </div>
                </div>
              );
            })}

            {localFrame > 150 && (
              <div style={{
                marginTop: 10,
                opacity: fadeIn(localFrame, 150, 20),
                transform: slideUp(localFrame, 150, 22, 20),
                background: `linear-gradient(135deg, ${VIOLET}, ${VIOLET_LIGHT})`,
                borderRadius: 14, padding: "12px 16px", textAlign: "center",
                fontFamily: "sans-serif", fontSize: 15, fontWeight: 700, color: WHITE,
              }}>
                ✨ 47 idées trouvées !
              </div>
            )}
          </div>
        </PhoneMockup>
      </div>
    </AbsoluteFill>
  );
};

// ─── SCÈNE 5 : Comparateur Prix (frames 1440-1710 = 9s) ──────────────────────
const ScenePrix = ({ frame }) => {
  const localFrame = frame - 1440;
  const titleOp = fadeIn(localFrame, 5, 20);
  const titleTr = slideUp(localFrame, 5, 25, 50);
  const phoneS = scaleIn(localFrame, 20, 30, 30);

  const links = [
    { site: "Amazon.fr", price: "549€", best: true, emoji: "🟠", delay: 40 },
    { site: "Fnac", price: "569€", best: false, emoji: "🟡", delay: 58 },
    { site: "Darty", price: "579€", best: false, emoji: "🔴", delay: 76 },
    { site: "Site officiel", price: "599€", best: false, emoji: "🌐", delay: 94 },
  ];

  return (
    <AbsoluteFill style={{ alignItems: "center", justifyContent: "center", flexDirection: "column" }}>
      <GradientBg />
      <Particles frame={localFrame} />

      <div style={{
        position: "absolute", top: 140,
        opacity: titleOp, transform: titleTr, textAlign: "center", padding: "0 60px",
      }}>
        <Tag color={GOLD}>💰 Meilleur prix</Tag>
        <div style={{
          fontFamily: "sans-serif", fontSize: 50, fontWeight: 800,
          color: WHITE, marginTop: 20, lineHeight: 1.2,
        }}>
          Compare & achète{"\n"}au meilleur prix
        </div>
      </div>

      <div style={{
        position: "absolute", bottom: 80,
        transform: `scale(${phoneS})`,
        opacity: fadeIn(localFrame, 20, 20),
      }}>
        <PhoneMockup frame={localFrame} startFrame={20}>
          <div style={{ padding: "0 14px" }}>
            <div style={{
              fontFamily: "sans-serif", fontSize: 13, fontWeight: 700,
              color: WHITE, marginBottom: 6,
            }}>PlayStation 5 Slim</div>
            <div style={{
              fontFamily: "sans-serif", fontSize: 11, color: GREY, marginBottom: 14,
            }}>Où acheter · Dès 549€</div>

            {links.map((l, i) => {
              const op = fadeIn(localFrame, l.delay, 16);
              const tr = slideUp(localFrame, l.delay, 18, 20);
              return (
                <div key={i} style={{
                  display: "flex", alignItems: "center", gap: 10,
                  background: l.best ? "rgba(16,185,129,0.08)" : "rgba(255,255,255,0.04)",
                  border: l.best ? "1.5px solid rgba(16,185,129,0.4)" : "1px solid rgba(255,255,255,0.07)",
                  borderRadius: 12, padding: "9px 12px", marginBottom: 8,
                  opacity: op, transform: tr,
                }}>
                  <span style={{ fontSize: 18 }}>{l.emoji}</span>
                  <span style={{
                    flex: 1, fontFamily: "sans-serif", fontSize: 13,
                    fontWeight: 600, color: WHITE,
                  }}>{l.site}</span>
                  {l.best && (
                    <span style={{
                      background: "#10B981", borderRadius: 6, padding: "2px 6px",
                      fontFamily: "sans-serif", fontSize: 9, fontWeight: 700, color: WHITE,
                    }}>Meilleur</span>
                  )}
                  <span style={{
                    fontFamily: "sans-serif", fontSize: 15, fontWeight: 700,
                    color: l.best ? "#10B981" : WHITE,
                  }}>{l.price}</span>
                </div>
              );
            })}
          </div>
        </PhoneMockup>
      </div>
    </AbsoluteFill>
  );
};

// ─── SCÈNE 6 : CTA Final (frames 1710-1800 = 3s) ─────────────────────────────
const SceneCTA = ({ frame }) => {
  const localFrame = frame - 1710;
  const logoOp = fadeIn(localFrame, 5, 20);
  const logoS = scaleIn(localFrame, 5, 25, 30);
  const textOp = fadeIn(localFrame, 20, 20);
  const btnOp = fadeIn(localFrame, 35, 20);
  const btnS = scaleIn(localFrame, 35, 20, 30);
  const glow = 0.5 + Math.sin(localFrame / 10) * 0.2;

  return (
    <AbsoluteFill style={{ alignItems: "center", justifyContent: "center", flexDirection: "column" }}>
      <GradientBg />
      <Particles frame={localFrame} />

      <div style={{
        position: "absolute",
        width: 500, height: 500, borderRadius: "50%",
        background: `radial-gradient(circle, ${VIOLET}${Math.round(glow * 100).toString(16).padStart(2, "0")} 0%, transparent 70%)`,
      }} />

      <div style={{
        textAlign: "center", alignItems: "center",
        display: "flex", flexDirection: "column", gap: 24,
      }}>
        <div style={{
          transform: `scale(${logoS})`, opacity: logoOp,
          fontFamily: "sans-serif", fontSize: 100, fontWeight: 900,
          color: WHITE, letterSpacing: -3,
          textShadow: `0 0 80px ${VIOLET}`,
        }}>
          doron.
        </div>

        <div style={{
          opacity: textOp,
          fontFamily: "sans-serif", fontSize: 36, fontWeight: 300,
          color: "rgba(255,255,255,0.7)", letterSpacing: 1,
        }}>
          Disponible sur iOS & Android
        </div>

        <div style={{
          opacity: btnOp, transform: `scale(${btnS})`,
          background: `linear-gradient(135deg, ${VIOLET}, ${VIOLET_LIGHT})`,
          borderRadius: 20, padding: "20px 60px",
          fontFamily: "sans-serif", fontSize: 36, fontWeight: 700, color: WHITE,
          boxShadow: `0 20px 60px ${VIOLET}55`,
        }}>
          Télécharge l'app 🎁
        </div>
      </div>
    </AbsoluteFill>
  );
};

// ─── Composition principale ───────────────────────────────────────────────────
export const DoronVideo = () => {
  const frame = useCurrentFrame();

  return (
    <AbsoluteFill style={{ background: NAVY, fontFamily: "system-ui, sans-serif" }}>
      <Sequence from={0} durationInFrames={90}>
        <SceneIntro frame={frame} />
      </Sequence>
      <Sequence from={90} durationInFrames={360}>
        <SceneWishlist frame={frame} />
      </Sequence>
      <Sequence from={450} durationInFrames={360}>
        <SceneAlbums frame={frame} />
      </Sequence>
      <Sequence from={810} durationInFrames={360}>
        <SceneSocial frame={frame} />
      </Sequence>
      <Sequence from={1170} durationInFrames={270}>
        <SceneQuestionnaire frame={frame} />
      </Sequence>
      <Sequence from={1440} durationInFrames={270}>
        <ScenePrix frame={frame} />
      </Sequence>
      <Sequence from={1710} durationInFrames={90}>
        <SceneCTA frame={frame} />
      </Sequence>
    </AbsoluteFill>
  );
};
