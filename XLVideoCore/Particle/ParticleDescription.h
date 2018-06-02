#pragma once
#include "Math.h"

namespace XLSimple2D
{
	/* 发射器类型 */
	enum class EmitterType
	{
		EMITTER_TYPE_GRAVITY,	/* 重力模式 */
		EMITTER_TYPE_RADIUS		/* 半径模式 */
	};

	/* 粒子运动模式 */
	enum class MotionMode
	{
		MOTION_MODE_FREE,		/* 粒子运动和发射器无关 */
		MOTION_MODE_RELATIVE	/* 粒子运动跟随发射器位置 */
	};

	/* 重力模式 */
	struct GravityMode
	{
		Vec2 vGravity;				/* 重力方向 */

		float fTangentialAccel;		/* 切向加速度 */
		float fTangentialAccelVar;	/* 径向加速度变化值 */

		float fRadialAccel;			/* 径向加速度 */
		float fRadialAccelVar;		/* 径向加速度变化值 */
	};

	/* 半径模式 */
	struct RadiusMode
	{
		float fBeginRadius;			/* 起始半径  */
		float fBeginRadiusVar;		/* 起始半径变化值 */

		float fEndRadius;			/* 结束半径 */
		float fEndRadiusVar;		/* 结束半径变化值 */

		float fSpinPerSecond;		/* 每秒旋转角度 */
		float fSpinPerSecondVar;	/* 每秒旋转角度变化值 */
	};


	class DLL_export ParticleDescription
	{
	public:
		ParticleDescription()
			: vEmitPos(0, 0)
			, vEmitPosVar(0, 0)
			, fEmitAngle(0)
			, fEmitAngleVar(0)
			, fEmitSpeed(0)
			, fEmitSpeedVar(0)
			, nParticleCount(0)
			, fEmitRate(0)
			, fDuration(-1)
			, emitterType(EmitterType::EMITTER_TYPE_GRAVITY)
			, motionMode(MotionMode::MOTION_MODE_FREE)
			, fLife(0)
			, fLifeVar(0)
			, cBeginColor(0, 0, 0, 0)
			, cBeginColorVar(0, 0, 0, 0)
			, cEndColor(0, 0, 0, 0)
			, cEndColorVar(0, 0, 0, 0)
			, fBeginSize(0)
			, fBeginSizeVar(0)
			, fEndSize(0)
			, fEndSizeVar(0)
			, fBeginSpin(0)
			, fBeginSpinVar(0)
			, fEndSpin(0)
			, fEndSpinVar(0)
		{
			gravityMode.fRadialAccel = 0;
			gravityMode.fRadialAccelVar = 0;
			gravityMode.fTangentialAccel = 0;
			gravityMode.fTangentialAccelVar = 0;
			gravityMode.vGravity.set(0, 0);

			radiusMode.fBeginRadius = 0;
			radiusMode.fBeginRadiusVar = 0;
			radiusMode.fEndRadius = 0;
			radiusMode.fEndRadiusVar = 0;
			radiusMode.fSpinPerSecond = 0;
			radiusMode.fSpinPerSecondVar = 0;
		}

		/* 发射器属性 */

		Vec2 vEmitPos;				/* 发射器位置 */
		Vec2 vEmitPosVar;			

		float fEmitAngle;			/* 发射器发射粒子角度 */
		float fEmitAngleVar;
				
		float fEmitSpeed;			/* 发射器发射粒子速度 */
		float fEmitSpeedVar;

		int nParticleCount;			/* 粒子数量 */
		float fEmitRate;			/* 粒子每秒发射速率 */
		float fDuration;			/* 发射器发射粒子时间 */

		EmitterType emitterType;
		MotionMode  motionMode;

		/* 粒子属性 */

		/* 粒子生命周期 */
		float fLife;
		float fLifeVar;

		/* 粒子的颜色变化 */
		Color cBeginColor;
		Color cBeginColorVar;
		Color cEndColor;
		Color cEndColorVar;

		/* 粒子的大小变化 */
		float fBeginSize;
		float fBeginSizeVar;
		float fEndSize;
		float fEndSizeVar;

		/* 粒子旋转角度变化 */
		float fBeginSpin;
		float fBeginSpinVar;
		float fEndSpin;
		float fEndSpinVar;

		GravityMode gravityMode;
		RadiusMode radiusMode;
	};
}
