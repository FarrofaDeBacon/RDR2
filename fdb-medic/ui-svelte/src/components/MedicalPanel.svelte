<script lang="ts">
  import { onMount, onDestroy } from 'svelte';
  import '../assets/css/medpanel.css';
  import weatheredPaper from '../assets/imgs/weathered_paper.png';
  import selectionBoxBg from '../assets/imgs/selection_box_bg_1d.png';
  import BodyPartBar from './BodyPartBar.svelte';

  export let wounds: any = {};
  export let treatments: any = [];
  export let infections: any = {};
  export let bodyPartHealth: any = {};
  export let injuryStates: any = {};
  export let infectionStages: any = {};
  export let bodyParts: any = {};
  export let uiColors: any = {};
  export let inventory: any = {};
  export let bandageTypes: any = {};
  export let isSelfExamination: boolean = false;
  export let translations: any = {};
  export let onClose: () => void;

  // Normalize treatments: Lua tables can arrive as objects instead of arrays
  $: normalizedTreatments = Array.isArray(treatments) ? treatments : Object.values(treatments || {});

  let showBandagePanel = false;

  function getBodyPartName(bodyPart: string): string {
    const bp = bodyPart.toLowerCase();
    if (translations && translations[`ui_body_${bp}`]) {
      return translations[`ui_body_${bp}`];
    }
    if (bodyParts && bodyParts[bodyPart]) {
      return bodyParts[bodyPart].label || bodyParts[bodyPart];
    }
    const fallbackNames: { [key: string]: string } = {
      'head': 'Head', 'spine': 'Spine', 'upbody': 'Upper Body', 'lowbody': 'Lower Body', 'upper': 'Upper Body', 'lower': 'Lower Body',
      'larm': 'Left Arm', 'rarm': 'Right Arm', 'lhand': 'Left Hand', 'rhand': 'Right Hand',
      'lleg': 'Left Leg', 'rleg': 'Right Leg', 'lfoot': 'Left Foot', 'rfoot': 'Right Foot'
    };
    return fallbackNames[bp] || bodyPart;
  }

  let showTourniquetPanel = false;
  let showTreatmentsPanel = false;
  let selectedBodyPart = '';
  let selectedTourniquetBodyPart = '';

  let loadingInventory = false;
  let currentInventory: any = null;
  let currentWounds: any = null;

  function handleKeyDown(event: KeyboardEvent) {
    if (event.key === 'Escape') {
      onClose();
    }
  }

  onMount(() => {
    window.addEventListener('keydown', handleKeyDown);
  });

  onDestroy(() => {
    window.removeEventListener('keydown', handleKeyDown);
  });

  function getHealthText(health: number) {
    if (health >= 80) return 'Healthy';
    if (health >= 60) return 'Minor Injury';
    if (health >= 40) return 'Moderate Injury';
    if (health >= 20) return 'Serious Injury';
    return 'Critical';
  }

  function getHealthColor(health: number) {
    if (health >= 70) return uiColors?.normal || 'var(--status-good)';
    if (health >= 30) return uiColors?.medium || 'var(--status-medium)';
    return uiColors?.low || 'var(--status-critical)';
  }

  $: bloodHealth = () => {
    const wound = wounds['BLOOD'] || wounds['blood'];
    return wound ? (wound.health || 100) : 100;
  };

  async function handleBandageClick() {
    showBandagePanel = true;
    showTourniquetPanel = false;
    showTreatmentsPanel = false;
    loadingInventory = true;
    currentInventory = null;
    currentWounds = null;

    try {
      const response = await fetch(`https://${(window as any).GetParentResourceName?.() || 'fdb-medic'}/get-current-inventory`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
      });

      const data = await response.json();
      currentInventory = data.inventory;
      currentWounds = data.wounds;
    } catch (error) {
      console.error('Failed to get inventory:', error);
      currentInventory = { bandages: [], tourniquets: [], medicines: [], injections: [] };
      currentWounds = {};
    } finally {
      loadingInventory = false;
    }
  }

  async function handleTourniquetClick() {
    showTourniquetPanel = true;
    showBandagePanel = false;
    showTreatmentsPanel = false;
    loadingInventory = true;
    currentInventory = null;
    currentWounds = null;

    try {
      const response = await fetch(`https://${(window as any).GetParentResourceName?.() || 'fdb-medic'}/get-current-inventory`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
      });

      const data = await response.json();
      currentInventory = data.inventory;
      currentWounds = data.wounds;
    } catch (error) {
      console.error('Failed to get inventory:', error);
      currentInventory = { bandages: [], tourniquets: [], medicines: [], injections: [] };
      currentWounds = {};
    } finally {
      loadingInventory = false;
    }
  }

  function handleTreatmentsClick() {
    showTreatmentsPanel = true;
    showBandagePanel = false;
    showTourniquetPanel = false;
  }

  function closePanels() {
    showBandagePanel = false;
    showTourniquetPanel = false;
    showTreatmentsPanel = false;
    selectedBodyPart = '';
    selectedTourniquetBodyPart = '';
    loadingInventory = false;
    currentInventory = null;
    currentWounds = null;
  }

  function applyBandage(bodyPart: string, bandageType: string) {
    fetch(`https://${(window as any).GetParentResourceName?.() || 'fdb-medic'}/apply-bandage`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ bodyPart, bandageType })
    }).catch(() => {});
    closePanels();
  }

  function applyTourniquet(bodyPart: string, tourniquetType: string) {
    fetch(`https://${(window as any).GetParentResourceName?.() || 'fdb-medic'}/apply-tourniquet`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ bodyPart, tourniquetType })
    }).catch(() => {});
    closePanels();
  }

  function replaceTreatment(bodyPart: string, type: string) {
    fetch(`https://${(window as any).GetParentResourceName?.() || 'fdb-medic'}/replace-treatment`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ bodyPart, treatmentType: type })
    }).catch(() => {});
  }

  function removeTreatment(bodyPart: string, type: string) {
    fetch(`https://${(window as any).GetParentResourceName?.() || 'fdb-medic'}/remove-treatment`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ bodyPart, treatmentType: type })
    }).catch(() => {});
  }
</script>

<style>
  /* Loading spinner animation */
  @keyframes spin {
    0% { transform: rotate(0deg); }
    100% { transform: rotate(360deg); }
  }

  /* Keep hands at original position */
  :global(.medic-lhand) { margin-top: 0.8vw !important; }
  :global(.medic-rhand) { margin-top: 0.8vw !important; }
  
  /* Move lower body down to proper position */
  :global(.medic-lower) { margin-top: 18vw !important; }
  
  /* Move action buttons right and down */
  :global(.medic-actions-right) {
    margin-left: 35vw !important;
    margin-top: -40vw !important;
  }
  
  /* Fix only the exit animation for tooltips - prevent width animation */
  :global(.action-tooltip) {
    transition: opacity 0.3s ease, transform 0.3s ease !important;
    white-space: nowrap !important;
  }
  
  /* Status tooltip styling */
  :global(.infection-tooltip) {
    position: absolute !important;
    top: 50% !important;
    left: 110% !important;
    transform: translateY(-50%) translateX(-10px) !important;
    border: none !important;
    border-radius: 8px !important;
    padding: 20px 24px !important;
    width: 320px !important;
    height: auto !important;
    min-height: 120px !important;
    z-index: 2000 !important;
    opacity: 0 !important;
    transition: opacity 0.3s ease, transform 0.3s ease !important;
    pointer-events: none !important;
    box-shadow: none !important;
    display: flex !important;
    flex-direction: column !important;
    justify-content: flex-start !important;
  }
  
  /* Hide body part icons completely from tooltip area */
  :global(.infection-tooltip .body-part-icon) {
    display: none !important;
  }
  
  /* Prevent any inherited background images in tooltip */
  :global(.infection-tooltip *) {
    background-image: none !important;
  }
  
  :global(.medic-head-first:hover .infection-tooltip),
  :global(.medic-spine-first:hover .infection-tooltip),
  :global(.medic-upper-first:hover .infection-tooltip),
  :global(.medic-larm-first:hover .infection-tooltip),
  :global(.medic-rarm-first:hover .infection-tooltip),
  :global(.medic-lhand-first:hover .infection-tooltip),
  :global(.medic-rhand-first:hover .infection-tooltip),
  :global(.medic-lleg-first:hover .infection-tooltip),
  :global(.medic-rleg-first:hover .infection-tooltip),
  :global(.medic-lfoot-first:hover .infection-tooltip),
  :global(.medic-rfoot-first:hover .infection-tooltip),
  :global(.medic-lower-first:hover .infection-tooltip) {
    opacity: 1 !important;
    transform: translateY(-50%) translateX(0) !important;
  }
  
  /* Bandage panel animations */
  @keyframes slideInFromRight {
    from { transform: translateX(100%); opacity: 0; }
    to { transform: translateX(0); opacity: 1; }
  }
  
  @keyframes buttonSlideOut {
    from { transform: translateX(0); opacity: 1; }
    to { transform: translateX(200%); opacity: 0; }
  }
  
  :global(.medic-actions-right .action-button.bandage-active),
  :global(.medic-actions-right .action-button.treatments-active),
  :global(.medic-actions-right .action-button.tourniquet-active) {
    animation: buttonSlideOut 0.3s ease-out forwards;
  }
  
  :global(.treatments-selection-panel) {
    animation: slideInFromRight 0.3s ease-out !important;
  }
  
  :global(.treatment-option:hover) {
    transform: scale(0.98);
    filter: brightness(1.1);
  }
  
  :global(.treatment-option button:hover) {
    transform: scale(0.95);
    filter: brightness(1.2);
  }
  
  /* Pain shake animation for wounded unbandaged body parts */
  @keyframes painShake {
    0%, 60% { transform: rotate(0deg) scale(1); }
    61% { transform: rotate(-5deg) scale(1.08); }
    63% { transform: rotate(6deg) scale(1.08); }
    65% { transform: rotate(-6deg) scale(1.08); }
    67% { transform: rotate(4deg) scale(1.08); }
    69% { transform: rotate(-4deg) scale(1.06); }
    71% { transform: rotate(5deg) scale(1.06); }
    73% { transform: rotate(-5deg) scale(1.06); }
    75% { transform: rotate(3deg) scale(1.04); }
    77% { transform: rotate(-3deg) scale(1.04); }
    79% { transform: rotate(2deg) scale(1.02); }
    81% { transform: rotate(-2deg) scale(1.02); }
    83% { transform: rotate(1deg) scale(1.01); }
    85%, 100% { transform: rotate(0deg) scale(1); }
  }
  
  /* Gentle pulse animation for bandaged body parts */
  @keyframes healingPulse {
    0%, 85% { transform: scale(1); opacity: 1; }
    90% { transform: scale(1.03); opacity: 0.9; }
    95% { transform: scale(1.05); opacity: 0.8; }
    100% { transform: scale(1); opacity: 1; }
  }
  
  :global(.wounded-body-part) { animation: painShake 5s ease-in-out infinite; }
  :global(.bandaged-body-part) { animation: healingPulse 5s ease-in-out infinite; }
  
  :global(.wounded-body-part:hover),
  :global(.bandaged-body-part:hover) { animation-play-state: paused; }
  
  :global(.medic-head-first.wounded-body-part) { animation-delay: 0.5s; }
  :global(.medic-upper-first.wounded-body-part) { animation-delay: 1.0s; }
  :global(.medic-larm-first.wounded-body-part) { animation-delay: 1.5s; }
  :global(.medic-rarm-first.wounded-body-part) { animation-delay: 2.0s; }
  :global(.medic-lower-first.wounded-body-part) { animation-delay: 2.5s; }
  :global(.medic-lleg-first.wounded-body-part) { animation-delay: 3.0s; }
  :global(.medic-rleg-first.wounded-body-part) { animation-delay: 3.5s; }
  
  :global(.medic-head-first.bandaged-body-part) { animation-delay: 0.8s; }
  :global(.medic-upper-first.bandaged-body-part) { animation-delay: 1.3s; }
  :global(.medic-larm-first.bandaged-body-part) { animation-delay: 1.8s; }
  :global(.medic-rarm-first.bandaged-body-part) { animation-delay: 2.3s; }
  :global(.medic-lower-first.bandaged-body-part) { animation-delay: 2.8s; }
  :global(.medic-lleg-first.bandaged-body-part) { animation-delay: 3.3s; }
  :global(.medic-rleg-first.bandaged-body-part) { animation-delay: 3.8s; }

  /* New CSS for legs/feet positioning */
  :global(.medic-details) {
    position: relative !important;
  }
  :global(.medic-lleg) {
    position: absolute !important;
    top: 22vw !important;
    left: 0vw !important;
    margin-top: 0 !important;
  }
  :global(.medic-rleg) {
    position: absolute !important;
    top: 22vw !important;
    left: 0vw !important;
    margin-top: 0 !important;
  }
  :global(.medic-lfoot) {
    position: absolute !important;
    top: 25vw !important;
    left: 0vw !important;
    margin-top: 0 !important;
  }
  :global(.medic-rfoot) {
    position: absolute !important;
    top: 25vw !important;
    left: 0vw !important;
    margin-top: 0 !important;
  }
</style>

<div class="medic-system medical-field-book" data-theme="light">
  <div class="medic-close" on:click={onClose} style="position: absolute; top: 20px; right: 30px; z-index: 10; font-size: 32px; color: var(--text-main); cursor: pointer;">
    &times;
  </div>
  <div class="medic-big">
    <div class="medic-label">{translations?.ui_medical || 'Medical'} <span>{translations?.ui_panel || 'Panel'}</span></div>
    <div class="medic-details">
      
      <BodyPartBar bodyPart="head" label={getBodyPartName("head").toUpperCase()} imageName="head" {wounds} {bodyPartHealth} {treatments} {infections} {injuryStates} {infectionStages} {uiColors} />
      <BodyPartBar bodyPart="spine" label={getBodyPartName("spine").toUpperCase()} imageName="spine" {wounds} {bodyPartHealth} {treatments} {infections} {injuryStates} {infectionStages} {uiColors} />
      <BodyPartBar bodyPart="upper" label={getBodyPartName("upbody").toUpperCase()} imageName="upper" {wounds} {bodyPartHealth} {treatments} {infections} {injuryStates} {infectionStages} {uiColors} />
      
      <!-- Front-facing view -->
      <BodyPartBar bodyPart="larm" label={getBodyPartName("larm").toUpperCase()} imageName="larm" {wounds} {bodyPartHealth} {treatments} {infections} {injuryStates} {infectionStages} {uiColors} />
      <BodyPartBar bodyPart="lhand" label={getBodyPartName("lhand").toUpperCase()} imageName="lhand" {wounds} {bodyPartHealth} {treatments} {infections} {injuryStates} {infectionStages} {uiColors} />
      <BodyPartBar bodyPart="rarm" label={getBodyPartName("rarm").toUpperCase()} imageName="rarm" {wounds} {bodyPartHealth} {treatments} {infections} {injuryStates} {infectionStages} {uiColors} />
      <BodyPartBar bodyPart="rhand" label={getBodyPartName("rhand").toUpperCase()} imageName="rhand" {wounds} {bodyPartHealth} {treatments} {infections} {injuryStates} {infectionStages} {uiColors} />
      
      <BodyPartBar bodyPart="lleg" label={getBodyPartName("lleg").toUpperCase()} imageName="lleg" {wounds} {bodyPartHealth} {treatments} {infections} {injuryStates} {infectionStages} {uiColors} />
      <BodyPartBar bodyPart="rleg" label={getBodyPartName("rleg").toUpperCase()} imageName="rleg" {wounds} {bodyPartHealth} {treatments} {infections} {injuryStates} {infectionStages} {uiColors} />
      
      <BodyPartBar bodyPart="lfoot" label={getBodyPartName("lfoot").toUpperCase()} imageName="lfoot" {wounds} {bodyPartHealth} {treatments} {infections} {injuryStates} {infectionStages} {uiColors} />
      <BodyPartBar bodyPart="rfoot" label={getBodyPartName("rfoot").toUpperCase()} imageName="rfoot" {wounds} {bodyPartHealth} {treatments} {infections} {injuryStates} {infectionStages} {uiColors} />
      
      <BodyPartBar bodyPart="lower" label={getBodyPartName("lowbody").toUpperCase()} imageName="lower" {wounds} {bodyPartHealth} {treatments} {infections} {injuryStates} {infectionStages} {uiColors} />
      
      <div class="medic-blood">
        <div class="medic-blood-first"><div></div></div>
        <div class="medic-blood-dd">
          <div class="medic-blood-dd-label">Blood Level: <span style="font-size: 1.3vh; color: var(--text-main); margin-left: 7px;">{getHealthText(bloodHealth())}</span></div>
          <div class="medic-blood-dd-full">
            <div class="medic-blood-dd-bar" style="width: {bloodHealth()}%; background-color: {getHealthColor(bloodHealth())};"></div>
          </div>
        </div>
      </div>
      
    </div>
    
    <!-- Action Buttons -->
    <div class="medic-actions-right">
      <!-- svelte-ignore a11y-click-events-have-key-events -->
      <!-- svelte-ignore a11y-no-static-element-interactions -->
      <div class={`action-button ${showBandagePanel ? 'bandage-active' : ''}`} on:click={handleBandageClick} data-tooltip="Apply Bandage">
        <i class="fas fa-plus-circle"></i>
        <span class="action-tooltip">Bandages</span>
      </div>
      <!-- svelte-ignore a11y-click-events-have-key-events -->
      <!-- svelte-ignore a11y-no-static-element-interactions -->
      <div class={`action-button ${showTreatmentsPanel ? 'treatments-active' : ''}`} on:click={handleTreatmentsClick} data-tooltip="View Active Treatments">
        <i class="fas fa-list-alt"></i>
        <span class="action-tooltip">Active Treatments</span>
      </div>
      <!-- svelte-ignore a11y-click-events-have-key-events -->
      <!-- svelte-ignore a11y-no-static-element-interactions -->
      <div class={`action-button ${showTourniquetPanel ? 'tourniquet-active' : ''}`} on:click={handleTourniquetClick} data-tooltip="Apply Tourniquet">
        <i class="fas fa-compress"></i>
        <span class="action-tooltip">Tourniquets</span>
      </div>
    </div>
  </div>
</div>

<!-- Bandage Selection Panel -->
{#if showBandagePanel}
  <div class="bandage-selection-panel" style="position: fixed; top: 5vh; right: 2vw; width: 22vw; height: 30vh; z-index: 10000;">
    <div class="treatments-detail-bg" style="background-image: url({weatheredPaper}); background-size: 100% 100%; background-repeat: no-repeat; background-position: center; width: 100%; height: 100%; padding: 20px; border-radius: 10px; box-shadow: none;">
      <div class="treatments-detail-header">
        <div class="treatments-detail-title" style="color: white; font-weight: bold;">APPLY BANDAGE</div>
        <div class="treatments-detail-subtitle" style="color: white;">
          {selectedBodyPart ? 'Select Bandage Type' : 'Select Body Part'}
        </div>
        <div class="treatments-close-btn" on:click={closePanels} style="position: absolute; top: 10px; right: 15px; font-size: 20px; color: white; cursor: pointer;">&times;</div>
      </div>
      <div class="treatments-detail-content" style="margin-top: 20px; max-height: 70%; overflow-y: auto; color: white;">
        {#if loadingInventory}
          <div style="text-align: center; padding: 40px 20px; color: white;">
            <div style="border: 4px solid rgba(255,255,255,0.3); border-top: 4px solid white; border-radius: 50%; width: 40px; height: 40px; animation: spin 1s linear infinite; margin: 0 auto 20px;"></div>
            <p style="font-style: italic;">{translations?.ui_checkingSupplies || 'Checking your supplies...'}</p>
          </div>
        {:else if !currentWounds || Object.keys(currentWounds).length === 0}
          <div style="text-align: center; padding: 40px 20px; color: var(--status-good); font-style: italic;">
            <p style="font-size: 16px; margin-bottom: 10px;">{translations?.ui_spickAndSpan || "You're lookin' spick and span here partner!"}</p>
            <p style="font-size: 14px;">{translations?.ui_noBandagesNeeded || 'No bandages needed at this time.'}</p>
          </div>
        {:else}
          {#each Object.entries(currentWounds) as [bodyPart, wound]}
            {@const hasBandages = currentInventory?.bandages && currentInventory.bandages.length > 0}
            {@const isDisabled = !hasBandages}
            <div
              class={`treatment-item ${isDisabled ? 'disabled' : ''}`}
              on:click={() => {
                if (hasBandages) {
                  applyBandage(bodyPart, currentInventory.bandages[0].itemName);
                }
              }}
              style="padding: 10px; margin: 6px 0; border: none; border-radius: 5px; cursor: {isDisabled ? 'not-allowed' : 'pointer'}; background-image: url({selectionBoxBg}); background-size: 100% 100%; background-repeat: no-repeat; background-position: center; transition: all 0.2s ease; color: {isDisabled ? 'var(--text-muted)' : 'white'}; min-height: 55px; opacity: {isDisabled ? 0.4 : 1}; filter: {isDisabled ? 'grayscale(100%)' : 'none'};"
            >
              {#if hasBandages}
                <div style="font-weight: bold; margin-bottom: 5px;">
                  🩹 {currentInventory.bandages[0].label} - {getBodyPartName(bodyPart).toUpperCase()}
                </div>
                <div style="font-size: 11px; color: var(--status-medium);">
                  Bleeding: Level {wound.bleedingLevel || 0}
                </div>
              {:else}
                <div style="font-weight: bold; margin-bottom: 5px; color: var(--text-muted);">
                  🩹 ???? - {getBodyPartName(bodyPart).toUpperCase()}
                </div>
                <div style="font-size: 11px; color: var(--border-color); font-style: italic;">
                  ({translations?.ui_noBandagesInInventory || 'No bandages in inventory'})
                </div>
              {/if}
            </div>
          {/each}
        {/if}
      </div>
    </div>
  </div>
{/if}

<!-- Tourniquet Selection Panel -->
{#if showTourniquetPanel}
  <div class="tourniquet-selection-panel" style="position: fixed; top: 60vh; right: 2vw; width: 22vw; height: 30vh; z-index: 10000;">
    <div class="treatments-detail-bg" style="background-image: url({weatheredPaper}); background-size: 100% 100%; background-repeat: no-repeat; background-position: center; width: 100%; height: 100%; padding: 20px; border-radius: 10px; box-shadow: none;">
      <div class="treatments-detail-header">
        <div class="treatments-detail-title" style="color: white; font-weight: bold;">{translations?.ui_applyTourniquetTitle || 'APPLY TOURNIQUET'}</div>
        <div class="treatments-detail-subtitle" style="color: white;">
          {selectedTourniquetBodyPart ? (translations?.ui_selectTourniquetType || 'Select Tourniquet Type') : (translations?.ui_selectSeverelyBleedingPart || 'Select Severely Bleeding Part')}
        </div>
        <div class="treatments-close-btn" on:click={closePanels} style="position: absolute; top: 10px; right: 15px; font-size: 20px; color: white; cursor: pointer;">&times;</div>
      </div>
      <div class="treatments-detail-content" style="margin-top: 20px; max-height: 70%; overflow-y: auto; color: white;">
        {#if loadingInventory}
          <div style="text-align: center; padding: 40px 20px; color: white;">
            <div style="border: 4px solid rgba(255,255,255,0.3); border-top: 4px solid white; border-radius: 50%; width: 40px; height: 40px; animation: spin 1s linear infinite; margin: 0 auto 20px;"></div>
            <p style="font-style: italic;">{translations?.ui_checkingSupplies || 'Checking your supplies...'}</p>
          </div>
        {:else if !currentWounds || Object.entries(currentWounds).filter(([_, w]: [string, any]) => (w.bleedingLevel || 0) >= 6).length === 0}
          <div style="text-align: center; padding: 40px 20px; color: var(--status-good); font-style: italic;">
            <p style="font-size: 16px; margin-bottom: 10px;">{translations?.ui_noSevereBleeding || "Ain't no severe bleedin' here!"}</p>
            <p style="font-size: 14px;">{translations?.ui_noTourniquetsNeeded || 'No tourniquets needed right now.'}</p>
          </div>
        {:else}
          {#each Object.entries(currentWounds).filter(([_, w]: [string, any]) => (w.bleedingLevel || 0) >= 6) as [bodyPart, wound]}
            {@const hasTourniquets = currentInventory?.tourniquets && currentInventory.tourniquets.length > 0}
            {@const isDisabled = !hasTourniquets}
            <div
              class={`treatment-item ${isDisabled ? 'disabled' : ''}`}
              on:click={() => {
                if (hasTourniquets) {
                  applyTourniquet(bodyPart, currentInventory.tourniquets[0].itemName);
                }
              }}
              style="padding: 10px; margin: 6px 0; border: none; border-radius: 5px; cursor: {isDisabled ? 'not-allowed' : 'pointer'}; background-image: url({selectionBoxBg}); background-size: 100% 100%; background-repeat: no-repeat; background-position: center; transition: all 0.2s ease; color: {isDisabled ? 'var(--text-muted)' : 'white'}; min-height: 55px; opacity: {isDisabled ? 0.4 : 1}; filter: {isDisabled ? 'grayscale(100%)' : 'none'};"
            >
              {#if hasTourniquets}
                <div style="font-weight: bold; margin-bottom: 5px;">
                  🩸 {currentInventory.tourniquets[0].label} - {getBodyPartName(bodyPart).toUpperCase()}
                </div>
                <div style="font-size: 11px; color: var(--status-critical); font-weight: bold;">
                  {translations?.ui_severeBleedingLevel || 'SEVERE BLEEDING: Level '}{wound.bleedingLevel || 0}
                </div>
              {:else}
                <div style="font-weight: bold; margin-bottom: 5px; color: var(--text-muted);">
                  🩸 ???? - {getBodyPartName(bodyPart).toUpperCase()}
                </div>
                <div style="font-size: 11px; color: var(--border-color); font-style: italic;">
                  ({translations?.ui_noTourniquetsInInventory || 'No tourniquets in inventory'})
                </div>
              {/if}
            </div>
          {/each}
        {/if}
      </div>
    </div>
  </div>
{/if}

<!-- Active Treatments Panel -->
{#if showTreatmentsPanel}
  <div class="treatments-selection-panel" style="position: fixed; top: 30vh; right: 2vw; width: 22vw; height: 30vh; z-index: 10000;">
    <div class="treatments-detail-bg" style="background-image: url({weatheredPaper}); background-size: 100% 100%; background-repeat: no-repeat; background-position: center; width: 100%; height: 100%; padding: 20px; border-radius: 10px; box-shadow: none;">
      <div class="treatments-detail-header">
        <div class="treatments-detail-title" style="color: white; font-weight: bold;">{translations?.ui_activeTreatmentsTitle || 'ACTIVE TREATMENTS'}</div>
        <div class="treatments-detail-subtitle" style="color: white;">
          {translations?.ui_manageTreatments || 'Manage your current treatments'}
        </div>
        <div class="treatments-close-btn" on:click={closePanels} style="position: absolute; top: 10px; right: 15px; font-size: 20px; color: white; cursor: pointer;">&times;</div>
      </div>
      <div class="treatments-detail-content" style="margin-top: 20px; max-height: 70%; overflow-y: auto; color: white;">
        {#if normalizedTreatments.length === 0}
          <div style="text-align: center; padding: 20px; color: white; font-style: italic;">
            {translations?.ui_noActiveTreatments || 'No active treatments'}
          </div>
        {:else}
          {#each normalizedTreatments as treatment}
            <div class="treatment-option" style="padding: 10px; margin: 6px 0; border: none; border-radius: 5px; background-image: url({selectionBoxBg}); background-size: 100% 100%; background-repeat: no-repeat; background-position: center; transition: all 0.2s ease; color: white; min-height: 55px; display: flex; flex-direction: column; position: relative;">
              <div style="font-weight: bold; margin-bottom: 8px; display: flex; justify-content: space-between; align-items: center;">
                <span>{treatment.bodyPart ? getBodyPartName(treatment.bodyPart).toUpperCase() : 'UNKNOWN'}</span>
                <span style="font-size: 12px; color: var(--status-good);">
                  {treatment.type === 'bandage' ? 'Bandaged' : treatment.type?.toUpperCase()}
                </span>
              </div>
              <div style="font-size: 11px; color: var(--text-muted); margin-bottom: 8px;">
                Item: {treatment.itemType || 'Unknown'} | {translations?.ui_appliedLbl || 'Applied:'} {treatment.appliedBy || 'Self'}
              </div>
              <div style="display: flex; gap: 5px; justify-content: flex-end;">
                <button on:click={() => replaceTreatment(treatment.bodyPart, treatment.type)} style="padding: 4px 8px; font-size: 10px; background-image: url({selectionBoxBg}); background-size: 100% 100%; border: none; border-radius: 3px; color: var(--status-medium); cursor: pointer; transition: all 0.2s ease;">
                  {translations?.ui_replace || 'Replace'}
                </button>
                
                {#if !wounds[treatment.bodyPart]}
                  <button on:click={() => removeTreatment(treatment.bodyPart, treatment.type)} style="padding: 4px 8px; font-size: 10px; background-image: url({selectionBoxBg}); background-size: 100% 100%; border: none; border-radius: 3px; color: var(--status-critical); cursor: pointer; transition: all 0.2s ease;">
                    {translations?.ui_remove || 'Remove'}
                  </button>
                {/if}
              </div>
            </div>
          {/each}
        {/if}
      </div>
    </div>
  </div>
{/if}
