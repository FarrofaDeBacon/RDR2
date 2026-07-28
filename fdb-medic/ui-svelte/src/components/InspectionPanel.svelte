<script lang="ts">
  import { onMount, onDestroy } from 'svelte';
  import weatheredPaper from '../assets/imgs/weathered_paper.png';
  import selectionBoxBg from '../assets/imgs/selection_box_bg_1d.png';

  export let data: any = {};
  export let translations: any = {};
  export let onClose: () => void;

  let currentView = 'home';
  let notification: { message: string, icon: string } | null = null;
  let checkingVitals = false;
  let vitalsProgress = 0;
  let vitalsChecked = false;

  let currentPatientVitals: any = null;

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

  function showNotification(message: string, icon: string = 'fa-check-circle') {
    notification = { message, icon };
    setTimeout(() => {
      notification = null;
    }, 4500);
  }

  function getVitals() {
    return {
      heartRate: currentPatientVitals?.heartRate || 72,
      status: currentPatientVitals?.status || 'Stable',
      statusColor: '#27ae60'
    };
  }

  $: vitals = getVitals();

  // Basic mock functions
  function startVitalsCheck() {
    checkingVitals = true;
    vitalsProgress = 0;
    const interval = setInterval(() => {
      vitalsProgress += 10;
      if (vitalsProgress >= 100) {
        clearInterval(interval);
        checkingVitals = false;
        vitalsChecked = true;
      }
    }, 300);
  }

  function stopVitalsCheck() {
    checkingVitals = false;
    vitalsProgress = 0;
  }
</script>

<style>
  .inspection-panel {
    position: fixed;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    width: 90vw;
    height: 80vh;
    display: flex;
    justify-content: space-between;
    align-items: flex-start;
    z-index: 1000;
  }

  .left-panel, .right-panel {
    width: 25vw;
    height: 100%;
    background-size: 100% 100%;
    background-position: center;
    background-repeat: no-repeat;
    padding: 2vw;
    display: flex;
    flex-direction: column;
    border-radius: 1vw;
  }

  .center-panel {
    width: 35vw;
    height: 100%;
    display: flex;
    flex-direction: column;
    align-items: center;
    position: relative;
  }

  .menu-btn {
    background-size: cover;
    background-position: center;
    color: white;
    border: none;
    padding: 1vw;
    margin: 0.5vw 0;
    width: 80%;
    border-radius: 0.5vw;
    font-size: 1vw;
    font-weight: bold;
    cursor: pointer;
    transition: transform 0.2s ease;
    display: flex;
    align-items: center;
  }

  .menu-btn:hover {
    transform: scale(1.05);
  }
</style>

<div class="inspection-panel">
  <!-- Left Panel: Vitals & Status -->
  <div class="left-panel" style="background-image: url({weatheredPaper});">
    <div style="text-align: center; color: white; font-size: 1.5vw; font-weight: bold; margin-bottom: 2vw; border-bottom: 2px solid rgba(255,255,255,0.3); padding-bottom: 1vw;">
      <i class="fas fa-file-medical-alt" style="margin-right: 0.5vw;"></i>
      {translations?.ui_patientChart || 'PATIENT CHART'}
    </div>
    
    <div style="color: white; font-size: 1vw; margin-bottom: 1vw;">
      <strong>Name:</strong> {data.playerName || 'Unknown'}
    </div>
    
    <!-- Vitals block -->
    <div style="background: rgba(0,0,0,0.3); padding: 1vw; border-radius: 0.5vw; margin-top: 1vw;">
      <div style="font-size: 1.2vw; color: white; margin-bottom: 1vw; text-align: center;">
        <i class="fas fa-heartbeat"></i> Vitals
      </div>
      {#if vitalsChecked}
        <div style="color: white; font-size: 1vw; display: flex; justify-content: space-between;">
          <span>Heart Rate:</span>
          <span style="color: {vitals.statusColor}">{vitals.heartRate} BPM</span>
        </div>
        <div style="color: white; font-size: 1vw; display: flex; justify-content: space-between; margin-top: 0.5vw;">
          <span>Status:</span>
          <span style="color: {vitals.statusColor}">{vitals.status}</span>
        </div>
      {:else}
        <div style="text-align: center;">
          <button on:mousedown={startVitalsCheck} on:mouseup={stopVitalsCheck} on:mouseleave={stopVitalsCheck} class="menu-btn" style="background-image: url({selectionBoxBg}); width: 100%; justify-content: center;">
            {checkingVitals ? 'CHECKING...' : 'CHECK VITALS'}
          </button>
        </div>
      {/if}
    </div>
  </div>

  <!-- Center Panel: Body Inspection / Menus -->
  <div class="center-panel">
    <div style="background-image: url({weatheredPaper}); background-size: 100% 100%; width: 100%; padding: 2vw; display: flex; flex-direction: column; align-items: center; border-radius: 1vw;">
      <div style="font-size: 1.5vw; color: white; font-weight: bold; margin-bottom: 2vw; border-bottom: 2px solid rgba(255,255,255,0.3); padding-bottom: 1vw; width: 100%; text-align: center;">
        {translations?.ui_medicalActions || 'MEDICAL ACTIONS'}
      </div>
      
      <button class="menu-btn" style="background-image: url({selectionBoxBg});" on:click={() => currentView = 'body-inspection'}>
        <i class="fas fa-search" style="margin-right: 1vw; width: 2vw; text-align: center;"></i>
        {translations?.ui_inspectBody || 'INSPECT BODY'}
      </button>
      
      <button class="menu-btn" style="background-image: url({selectionBoxBg});" on:click={() => currentView = 'bandage'}>
        <i class="fas fa-band-aid" style="margin-right: 1vw; width: 2vw; text-align: center;"></i>
        {translations?.ui_applyBandage || 'APPLY BANDAGE'}
      </button>
      
      <button class="menu-btn" style="background-image: url({selectionBoxBg});" on:click={() => currentView = 'medicine'}>
        <i class="fas fa-pills" style="margin-right: 1vw; width: 2vw; text-align: center;"></i>
        {translations?.ui_administerMedicine || 'ADMINISTER MEDICINE'}
      </button>

      <button class="menu-btn" style="background-image: url({selectionBoxBg}); margin-top: auto; background-color: rgba(231, 76, 60, 0.5);" on:click={onClose}>
        <i class="fas fa-times" style="margin-right: 1vw; width: 2vw; text-align: center;"></i>
        CLOSE
      </button>
    </div>
  </div>

  <!-- Right Panel: Assessment Log -->
  <div class="right-panel" style="background-image: url({weatheredPaper});">
    <div style="text-align: center; color: white; font-size: 1.5vw; font-weight: bold; margin-bottom: 2vw; border-bottom: 2px solid rgba(255,255,255,0.3); padding-bottom: 1vw;">
      <i class="fas fa-clipboard-list" style="margin-right: 0.5vw;"></i>
      {translations?.ui_assessmentLog || 'ASSESSMENT LOG'}
    </div>
    
    <div style="flex-grow: 1; overflow-y: auto; background: rgba(0,0,0,0.3); padding: 1vw; border-radius: 0.5vw; color: white; font-size: 0.9vw;">
      <div style="font-style: italic; color: rgba(255,255,255,0.5);">
        Log started...
      </div>
    </div>
  </div>

  {#if notification}
    <div style="position: fixed; top: 2vw; left: 50%; transform: translateX(-50%); background-image: url({weatheredPaper}); background-size: 100% 100%; padding: 1vw 2vw; color: white; font-weight: bold; border-radius: 0.5vw; display: flex; align-items: center; gap: 1vw; z-index: 1001;">
      <i class={`fas ${notification.icon}`} style="color: #27ae60; font-size: 1.5vw;"></i>
      {notification.message}
    </div>
  {/if}
</div>
