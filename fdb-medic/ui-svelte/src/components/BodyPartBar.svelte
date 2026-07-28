<script lang="ts">
  import weatheredPaper from '../assets/imgs/weathered_paper.png';

  export let bodyPart: string;
  export let label: string;
  export let imageName: string;
  export let wounds: any;
  export let bodyPartHealth: any;
  export let treatments: any[];
  export let infections: any;
  export let injuryStates: any;
  export let infectionStages: any;
  export let uiColors: any;

  function mapBodyPartName(part: string) {
    const bodyPartMap: { [key: string]: string } = {
      'head': 'HEAD',
      'neck': 'NECK', 
      'spine': 'SPINE',
      'upper': 'UPPER_BODY',
      'lower': 'LOWER_BODY',
      'larm': 'LARM',
      'rarm': 'RARM',
      'lhand': 'LHAND',
      'rhand': 'RHAND',
      'lleg': 'LLEG',
      'rleg': 'RLEG',
      'lfoot': 'LFOOT',
      'rfoot': 'RFOOT',
      'blood': 'BLOOD'
    };
    return bodyPartMap[part] || part.toUpperCase();
  }

  $: configBodyPart = mapBodyPartName(bodyPart);

  $: getHealthPercentage = () => {
    if (bodyPartHealth && bodyPartHealth[configBodyPart]) {
      return bodyPartHealth[configBodyPart].percentage;
    }
    const wound = wounds[configBodyPart] || wounds[bodyPart];
    return wound ? (wound.health || 100) : 100;
  };
  
  $: health = getHealthPercentage();

  $: getHasBandage = () => {
    return treatments?.some(treatment => 
      treatment.bodyPart === configBodyPart && treatment.type === 'bandage'
    ) || false;
  };

  $: getHasTourniquet = () => {
    return treatments?.some(treatment => 
      treatment.bodyPart === configBodyPart && treatment.type === 'tourniquet'
    ) || false;
  };

  $: hasBandage = getHasBandage();
  $: hasTourniquet = getHasTourniquet();

  $: getInfectionInfo = () => {
    if (infections && infections[configBodyPart]) {
      return infections[configBodyPart];
    }
    return { stage: 0, symptom: null };
  };

  $: infection = getInfectionInfo();

  $: getHealthColor = () => {
    if (hasBandage) return uiColors?.bandaged || '#3498db';
    if (hasTourniquet) return uiColors?.tourniquet || '#f1c40f';
    if (infection.stage > 0) return uiColors?.infected || '#9C27B0';
    if (health >= 70) return uiColors?.normal || '#27ae60';
    if (health >= 30) return uiColors?.medium || '#f39c12';
    return uiColors?.low || '#e74c3c';
  };

  $: color = getHealthColor();

  $: getHealthText = () => {
    if (health >= 80) return 'Healthy';
    if (health >= 60) return 'Minor Injury';
    if (health >= 40) return 'Moderate Injury';
    if (health >= 20) return 'Serious Injury';
    return 'Critical';
  };

  $: text = getHealthText();

  function getBodyPartDisplayName(part: string) {
    const names: { [key: string]: string } = {
      'HEAD': 'head',
      'NECK': 'neck',
      'SPINE': 'spine', 
      'UPPER_BODY': 'chest',
      'LOWER_BODY': 'stomach',
      'LARM': 'left arm',
      'RARM': 'right arm',
      'LHAND': 'left hand',
      'RHAND': 'right hand',
      'LLEG': 'left leg',
      'RLEG': 'right leg',
      'LFOOT': 'left foot',
      'RFOOT': 'right foot'
    };
    return names[part] || part.toLowerCase();
  }

  function getPainThought(painLevel: number) {
    if (!painLevel || painLevel === 0) return null;
    const bodyPartName = getBodyPartDisplayName(configBodyPart);
    if (injuryStates && injuryStates[painLevel]) {
      return `My ${bodyPartName.toLowerCase()} ${injuryStates[painLevel].pain.toLowerCase()}`;
    }
    return `My ${bodyPartName.toLowerCase()} is in pain`;
  }

  function getBleedingThought(bleedingLevel: number) {
    if (!bleedingLevel || bleedingLevel === 0) return null;
    const bodyPartName = getBodyPartDisplayName(configBodyPart);
    if (injuryStates && injuryStates[bleedingLevel]) {
      return `My ${bodyPartName.toLowerCase()} ${injuryStates[bleedingLevel].bleeding.toLowerCase()}`;
    }
    return `My ${bodyPartName.toLowerCase()} is bleeding`;
  }

  function getInfectionStageInfo(stage: number) {
    if (infectionStages && infectionStages[stage]) {
      return infectionStages[stage];
    }
    const defaultStages: { [key: number]: { name: string; color: string } } = {
      0: { name: "Healthy", color: "#00ff00" },
      1: { name: "Early Infection", color: "#ffff00" },
      2: { name: "Moderate Infection", color: "#ff8000" },
      3: { name: "Serious Infection", color: "#ff4000" },
      4: { name: "Severe Infection", color: "#ff0000" }
    };
    return defaultStages[stage] || defaultStages[0];
  }

  $: wound = wounds[configBodyPart] || wounds[bodyPart];
  $: painLevel = wound?.painLevel || 0;
  $: bleedingLevel = wound?.bleedingLevel || 0;
  $: hasWoundIssues = painLevel > 0 || bleedingLevel > 0;
  $: hasVisibleInfection = infection.stage >= 3 && !hasBandage;
  $: hasAnyStatus = hasVisibleInfection || hasBandage || hasTourniquet || hasWoundIssues;
  
  $: infectionStage = getInfectionStageInfo(infection.stage);

  $: getAnimationClass = () => {
    if (!hasWoundIssues) return '';
    if (hasBandage) return 'bandaged-body-part';
    return 'wounded-body-part';
  };
</script>

<div class={`medic-${bodyPart.toLowerCase()}`}>
  <div class={`medic-${bodyPart.toLowerCase()}-first ${getAnimationClass()}`} style="position: relative">
    <div class="body-part-icon"></div>
    <div class="body-part-label">{label}</div>
    
    {#if hasAnyStatus}
    <div 
      class="infection-tooltip" 
      style="background-image: url({weatheredPaper}); background-size: 100% 100%; background-repeat: no-repeat; background-position: center;"
    >
      <div class="status-header" style="color: white; font-weight: bold; margin-bottom: 8px;">
        Status
      </div>
      
      {#if hasBandage}
        <div class="status-item" style="color: #3498db; margin-bottom: 6px; font-style: italic;">
          "The bandage feels secure and is helping the healing."
        </div>
      {/if}
      
      {#if hasTourniquet}
        <div class="status-item" style="color: #f1c40f; margin-bottom: 6px; font-style: italic;">
          "The tourniquet is stopping the bleeding but feels tight."
        </div>
      {/if}
      
      {#if hasVisibleInfection}
        <div class="status-item" style="color: {infectionStage.color}; margin-bottom: 6px; font-style: italic;">
          "{infection.symptom || 'Something doesn\'t feel right here...'}"
        </div>
      {/if}
      
      {#if getPainThought(painLevel)}
        <div class="status-item" style="color: #ff6b6b; margin-bottom: 6px; font-style: italic;">
          "{getPainThought(painLevel)}"
        </div>
      {/if}
      
      {#if getBleedingThought(bleedingLevel)}
        <div class="status-item" style="color: #e74c3c; margin-bottom: 6px; font-style: italic;">
          "{getBleedingThought(bleedingLevel)}"
        </div>
      {/if}
      
      {#if !hasAnyStatus}
        <div class="status-item" style="color: #27ae60; margin-bottom: 6px; font-style: italic;">
          "This feels fine."
        </div>
      {/if}
    </div>
    {/if}
  </div>
  <div class={`medic-${bodyPart.toLowerCase()}-dd`}>
    <div class={`medic-${bodyPart.toLowerCase()}-dd-label`}>
      {label}: <span style="font-size: 1.3vh; color: #fff; margin-left: 7px;">{text}</span>
    </div>
    <div class={`medic-${bodyPart.toLowerCase()}-dd-full`}>
      <div 
        class={`medic-${bodyPart.toLowerCase()}-dd-bar`}
        style="width: {health}%; background-color: {color}; transition: all 0.3s ease;"
      ></div>
    </div>
  </div>
</div>
