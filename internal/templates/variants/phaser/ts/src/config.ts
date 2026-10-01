import { Preloader } from './scenes/Preloader.js';
import { Types } from 'phaser';

export const config = {
  title: 'Card Memory Game',
  type: Phaser.AUTO,
  width: 549,
  height: 480,
  parent: 'game-container',
  backgroundColor: '#192a56',
  pixelArt: true,
  scale: {
    mode: Phaser.Scale.FIT,
    autoCenter: Phaser.Scale.CENTER_BOTH
  },
  scene: [
    Preloader
  ],

} satisfies Types.Core.GameConfig;
