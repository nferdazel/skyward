<script lang="ts">
	import { onMount } from 'svelte';

	type Props = {
		message?: string;
		subMessage?: string;
		showLogs?: boolean;
	};

	let {
		message = 'INITIALIZING AVIONICS SYSTEMS...',
		subMessage = 'ESTABLISHING SECURE SATELLITE TELEMETRY LINK',
		showLogs = true
	}: Props = $props();

	let step = $state(0);
	const logs = [
		'AVIONICS FLIGHT CONTROLLER: NOMINAL',
		'CONNECTING TO ATC SATELLITE RELAY...',
		'AUTHENTICATING SKYWARD FLIGHT DISPATCH...',
		'SYNCHRONIZING FLEET TELEMETRY MATRIX...',
		'PRIMARY FLIGHT DISPLAY READY.'
	];

	onMount(() => {
		const timer = setInterval(() => {
			if (step < logs.length - 1) {
				step++;
			}
		}, 320);
		return () => clearInterval(timer);
	});
</script>

<div class="terminal-container" role="status" aria-live="polite">
	<!-- CRT raster scanline texture overlay -->
	<div class="crt-overlay" aria-hidden="true"></div>

	<div class="terminal-frame">
		<div class="terminal-header">
			<div class="status-cluster">
				<span class="radar-dot" aria-hidden="true"></span>
				<span class="sys-label mono">SKYWARD // AVIONICS COMMAND TERMINAL v2.0</span>
			</div>
			<span class="sys-code mono">SYS.RDY</span>
		</div>

		<div class="primary-message mono">
			<span class="prompt" aria-hidden="true">&gt;</span>
			<span class="text">{message}</span>
			<span class="cursor" aria-hidden="true">_</span>
		</div>

		{#if showLogs}
			<div class="log-stream mono" aria-hidden="true">
				{#each logs.slice(0, step + 1) as logLine, i (i)}
					<div class="log-line">
						<span class="timestamp">[SYS.{(i + 1) * 120}ms]</span>
						<span class="log-text">{logLine}</span>
					</div>
				{/each}
			</div>
		{/if}

		<div class="progress-bar-container" aria-hidden="true">
			<div class="progress-fill" style="width: {((step + 1) / logs.length) * 100}%;"></div>
		</div>

		<div class="sub-message">
			<span class="sub-text micro-label">{subMessage}</span>
		</div>
	</div>
</div>

<style>
	.terminal-container {
		position: fixed;
		inset: 0;
		z-index: 9999;
		display: flex;
		align-items: center;
		justify-content: center;
		background: var(--color-bg, #080b10);
		font-family: var(--font-mono, 'IBM Plex Mono', monospace);
		color: var(--color-text-primary, #dde2ea);
		padding: var(--space-md);
		overflow: hidden;
		user-select: none;
	}

	.crt-overlay {
		position: absolute;
		inset: 0;
		pointer-events: none;
		background: var(--texture-scanline);
		opacity: 0.5;
	}

	.terminal-frame {
		position: relative;
		width: 100%;
		max-width: 580px;
		background: var(--color-surface, #0f1319);
		border: 1px solid var(--color-border-highlight, rgba(255, 255, 255, 0.15));
		border-radius: var(--radius-default, 4px);
		box-shadow:
			0 0 24px rgba(0, 0, 0, 0.7),
			inset 0 1px 0 rgba(255, 255, 255, 0.1);
		padding: var(--space-xl, 20px);
		display: flex;
		flex-direction: column;
		gap: var(--space-md, 12px);
	}

	.terminal-header {
		display: flex;
		align-items: center;
		justify-content: space-between;
		padding-bottom: var(--space-xs, 4px);
		border-bottom: 1px solid var(--color-border-subtle, rgba(255, 255, 255, 0.05));
	}

	.status-cluster {
		display: flex;
		align-items: center;
		gap: var(--space-sm, 8px);
	}

	.radar-dot {
		width: 8px;
		height: 8px;
		background: var(--color-success, #34d07b);
		border-radius: 50%;
		box-shadow: var(--glow-success, 0 0 12px rgba(52, 208, 123, 0.35));
		animation: radar-pulse 1.4s infinite;
	}

	.sys-label {
		font-size: 11px;
		font-weight: 600;
		letter-spacing: 0.12em;
		color: var(--color-text-secondary, #909fb3);
	}

	.sys-code {
		font-size: 10px;
		letter-spacing: 0.08em;
		color: var(--color-accent, #5b9ee0);
	}

	.primary-message {
		font-size: 15px;
		font-weight: 600;
		letter-spacing: 0.06em;
		display: flex;
		align-items: center;
		gap: var(--space-sm, 8px);
		color: var(--color-text-primary, #dde2ea);
	}

	.prompt {
		color: var(--color-accent, #5b9ee0);
	}

	.cursor {
		color: var(--color-accent, #5b9ee0);
		animation: blink 0.9s infinite;
	}

	.log-stream {
		display: flex;
		flex-direction: column;
		gap: 6px;
		min-height: 96px;
		padding: var(--space-sm, 8px);
		background: var(--color-surface-2, #161c25);
		border: 1px solid var(--color-border-subtle, rgba(255, 255, 255, 0.05));
		border-radius: var(--radius-tight, 2px);
	}

	.log-line {
		font-size: 12px;
		display: flex;
		gap: var(--space-sm, 8px);
		color: var(--color-text-secondary, #909fb3);
	}

	.timestamp {
		color: var(--color-teal, #3aafa0);
		font-size: 11px;
	}

	.log-text {
		color: var(--color-text-primary, #dde2ea);
	}

	.progress-bar-container {
		height: 4px;
		width: 100%;
		background: var(--color-surface-2, #161c25);
		border-radius: var(--radius-tight, 2px);
		overflow: hidden;
	}

	.progress-fill {
		height: 100%;
		background: var(--color-accent, #5b9ee0);
		box-shadow: var(--glow-accent, 0 0 12px rgba(91, 158, 224, 0.35));
		transition: width 240ms ease-out;
	}

	.sub-message {
		padding-top: var(--space-xs, 4px);
		border-top: 1px solid var(--color-border-subtle, rgba(255, 255, 255, 0.05));
		font-size: 11px;
		color: var(--color-text-muted, #8a99ad);
		letter-spacing: 0.08em;
	}

	@keyframes blink {
		0%,
		49% {
			opacity: 1;
		}
		50%,
		100% {
			opacity: 0;
		}
	}

	@media (prefers-reduced-motion: reduce) {
		.radar-dot,
		.cursor {
			animation: none;
		}
		.progress-fill {
			transition: none;
		}
	}
</style>
