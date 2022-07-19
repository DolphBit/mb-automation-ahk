#NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn ; Enable warnings to assist with detecting common errors.

global G_STYLES := {}

G_STYLES.main := {}
G_STYLES.main.color := "White"
ImageButton.SetGuiColor(G_STYLES.main.color)

/*
   1     Mode
   2     StartColor
   3     TargetColor
   4     TextColor
   5     Rounded
   6     GuiColor
   7     BorderColor
   8     BorderWidth
*/

G_STYLES.btn := {}
G_STYLES.btn.danger := [ [0, 0x80FFD8D7, , , 0, , 0x80D43F3A, 1]
, [0, 0x80F0B9B8, , , 0, , 0x80D43F3A, 1]
, [0, 0x80E27C79, , , 0, , 0x80D43F3A, 1]
, [0, 0x80F0F0F0, , , 0, , 0x80D43F3A, 1] ]

G_STYLES.btn.danger_round := [ [0, 0x80FFD8D7, , , 8, , 0x80D43F3A, 2]
, [0, 0x80F0B9B8, , , 8, , 0x80D43F3A, 2]
, [0, 0x80E27C79, , , 8, , 0x80D43F3A, 2]
, [0, 0x80F0F0F0, , , 8, , 0x80D43F3A, 2] ]

G_STYLES.btn.main := [ [0, 0xFF007bff, , "White", 0, , 0xFF007bff, 1]
, [0, 0xFF0069d9, , , 0, , 0xFF0062cc, 1]
, [0, 0xFF0062cc, , , 0, , 0xFF005cbf, 1]
, [0, 0x80F0F0F0, , , 0, , 0xFF007bff, 1] ]

G_STYLES.btn.secondary := [ [0, 0xFF6c757d, , "White", 0, , 0xFF6c757d, 1]
, [0, 0xFF0069d9, , , 0, , 0xFF0062cc, 1]
, [0, 0xFF0062cc, , , 0, , 0xFF005cbf, 1]
, [0, 0x80F0F0F0, , , 0, , 0xFF007bff, 1] ]

G_STYLES.btn.info := [ [0, 0x80C6E9F4, , , 0, , 0x8046B8DA, 1]
, [0, 0x8086D0E7, , , 0, , 0x8046B8DA, 1]
, [0, 0x8046B8DA, , , 0, , 0x8046B8DA, 1]
, [0, 0x80F0F0F0, , , 0, , 0x8046B8DA, 1] ]

G_STYLES.btn.success := [ [0, 0x80C6E6C6, , , 0, , 0x805CB85C, 1]
, [0, 0x8091CF91, , , 0, , 0x805CB85C, 1]
, [0, 0x805CB85C, , , 0, , 0x805CB85C, 1]
, [0, 0x80F0F0F0, , , 0, , 0x805CB85C, 1] ]
