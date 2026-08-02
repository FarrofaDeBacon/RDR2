<script lang="ts">
  import { createEventDispatcher } from 'svelte';
  import bodyFleshImg from '../assets/imgs/anatomy_v2/body_flesh.svg';
  import bodySkeletonImg from '../assets/imgs/anatomy_v2/body_skeleton.svg';
  
  export let wounds: any = {};
  export let treatments: any = [];
  export let bodyParts: any = {};
  export let inspectedBones: Set<string> = new Set();
  
  const dispatch = createEventDispatcher();
  
  let viewMode: 'flesh' | 'skeleton' = 'flesh';

  function toggleViewMode() {
    viewMode = viewMode === 'flesh' ? 'skeleton' : 'flesh';
  }

  // Lista de partes do corpo interativas
  const bodyPartZones = [
    { id: 'head', label: 'Head', top: '5%', left: '45%', width: '10%', height: '12%' },
    { id: 'upper', label: 'Upper Body', top: '18%', left: '40%', width: '20%', height: '20%' },
    { id: 'lower', label: 'Lower Body', top: '38%', left: '40%', width: '20%', height: '15%' },
    { id: 'larm', label: 'Left Arm', top: '20%', left: '60%', width: '12%', height: '22%' },
    { id: 'rarm', label: 'Right Arm', top: '20%', left: '28%', width: '12%', height: '22%' },
    { id: 'lhand', label: 'Left Hand', top: '42%', left: '65%', width: '8%', height: '10%' },
    { id: 'rhand', label: 'Right Hand', top: '42%', left: '27%', width: '8%', height: '10%' },
    { id: 'lleg', label: 'Left Leg', top: '53%', left: '50%', width: '12%', height: '25%' },
    { id: 'rleg', label: 'Right Leg', top: '53%', left: '38%', width: '12%', height: '25%' },
    { id: 'lfoot', label: 'Left Foot', top: '78%', left: '52%', width: '10%', height: '10%' },
    { id: 'rfoot', label: 'Right Foot', top: '78%', left: '38%', width: '10%', height: '10%' },
    { id: 'spine', label: 'Spine', top: '18%', left: '30%', width: '10%', height: '15%' }, 
  ];

  function getPartStatus(partId: string) {
    let status = { hasWound: false, isBleeding: false, isCritical: false, hasFracture: false };
    const partWound = wounds[partId];
    if (partWound) {
      status.hasWound = true;
      status.isBleeding = partWound.bleeding > 0;
      status.isCritical = partWound.bleeding >= 60 || partWound.severity >= 75;
      
      // Checa se há fratura
      if (partWound.boneIntegrity && partWound.boneIntegrity !== 'Intact') {
        status.hasFracture = true;
      }
    }
    return status;
  }

  function handlePartClick(partId: string) {
    dispatch('selectPart', partId);
  }
</script>

<style>
  .triage-container {
    position: relative;
    width: 100%;
    height: 100%;
    display: flex;
    justify-content: center;
    align-items: center;
    flex-direction: column;
  }

  .toggle-btn {
    position: absolute;
    top: 20px;
    right: 20px;
    background: rgba(20, 20, 20, 0.8);
    border: 1px solid var(--leather-stitch);
    color: var(--text-color);
    padding: 10px 20px;
    font-family: 'Western', serif;
    cursor: pointer;
    z-index: 10;
    transition: all 0.2s;
  }
  .toggle-btn:hover {
    background: rgba(226,199,146, 0.2);
  }

  .body-silhouette-bg {
    position: relative;
    height: 90%;
    width: 45vh; /* approximate 1:2 ratio */
    background-size: contain;
    background-position: center;
    background-repeat: no-repeat;
    /* Remover bordas placeholder agora que temos imagens */
  }

  .hitbox {
    position: absolute;
    cursor: pointer;
    border: 1px dashed rgba(226,199,146, 0.1); /* Manter levemente visível para debug inicial */
    transition: all 0.2s ease;
    display: flex;
    justify-content: center;
    align-items: center;
  }

  .hitbox:hover {
    background-color: rgba(226,199,146, 0.2);
    border: 1px solid rgba(226,199,146, 0.8);
  }

  /* Modos visuais dependendo da view */
  .hitbox.bleeding {
    background-color: rgba(180, 0, 0, 0.2);
    box-shadow: inset 0 0 15px rgba(180, 0, 0, 0.4);
    border: 1px solid rgba(180, 0, 0, 0.5);
  }

  .hitbox.critical {
    background-color: rgba(220, 0, 0, 0.4);
    box-shadow: inset 0 0 20px rgba(220, 0, 0, 0.6);
    border: 2px solid rgba(220, 0, 0, 0.8);
    animation: pulse-critical 1.5s infinite;
  }

  .hitbox.fracture {
    background-color: rgba(255, 200, 0, 0.3);
    box-shadow: inset 0 0 20px rgba(255, 200, 0, 0.5);
    border: 2px solid rgba(255, 200, 0, 0.8);
    animation: pulse-fracture 1s infinite;
  }

  @keyframes pulse-critical {
    0% { opacity: 0.7; }
    50% { opacity: 1; }
    100% { opacity: 0.7; }
  }

  @keyframes pulse-fracture {
    0% { opacity: 0.5; box-shadow: inset 0 0 10px rgba(255,200,0,0.3); }
    50% { opacity: 1; box-shadow: inset 0 0 25px rgba(255,200,0,0.7); }
    100% { opacity: 0.5; box-shadow: inset 0 0 10px rgba(255,200,0,0.3); }
  }

</style>

<div class="triage-container">
  
  <button class="toggle-btn" on:click={toggleViewMode}>
    {viewMode === 'flesh' ? 'Ativar Raio-X' : 'Modo Carne'}
  </button>

  <div class="body-silhouette-bg" style="background-image: url({viewMode === 'flesh' ? bodyFleshImg : bodySkeletonImg});">
    <!-- Overlay hitboxes for interaction -->
    {#each bodyPartZones as part}
      {@const status = getPartStatus(part.id)}
      
      <!-- Lógica: Mostrar sangramento no modo Carne, mostrar Fratura no modo Esqueleto -->
      {@const isGlowingFracture = viewMode === 'skeleton' && status.hasFracture}
      {@const isGlowingBlood = viewMode === 'flesh' && status.isBleeding}
      {@const isGlowingCritical = viewMode === 'flesh' && status.isCritical}

      <div 
        class="hitbox {isGlowingCritical ? 'critical' : ''} {isGlowingBlood && !isGlowingCritical ? 'bleeding' : ''} {isGlowingFracture ? 'fracture' : ''}"
        style="top: {part.top}; left: {part.left}; width: {part.width}; height: {part.height};"
        on:click={() => handlePartClick(part.id)}
        title={part.label}
      >
        <!-- Deixando o texto invisível a menos que passe o mouse, mas por agora fica semi-transparente para ajudar a alinhar -->
        <div style="color: rgba(255,255,255,0.4); font-size: 1vh; text-align: center; pointer-events: none;">{part.label}</div>
      </div>
    {/each}
  </div>
</div>
