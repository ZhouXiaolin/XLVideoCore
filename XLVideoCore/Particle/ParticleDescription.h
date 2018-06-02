#pragma once
#include "Math.h"

namespace XLSimple2D
{
	/* ���������� */
	enum class EmitterType
	{
		EMITTER_TYPE_GRAVITY,	/* ����ģʽ */
		EMITTER_TYPE_RADIUS		/* �뾶ģʽ */
	};

	/* �����˶�ģʽ */
	enum class MotionMode
	{
		MOTION_MODE_FREE,		/* �����˶��ͷ������޹� */
		MOTION_MODE_RELATIVE	/* �����˶����淢����λ�� */
	};

	/* ����ģʽ */
	struct GravityMode
	{
		Vec2 vGravity;				/* �������� */

		float fTangentialAccel;		/* ������ٶ� */
		float fTangentialAccelVar;	/* ������ٶȱ仯ֵ */

		float fRadialAccel;			/* ������ٶ� */
		float fRadialAccelVar;		/* ������ٶȱ仯ֵ */
	};

	/* �뾶ģʽ */
	struct RadiusMode
	{
		float fBeginRadius;			/* ��ʼ�뾶  */
		float fBeginRadiusVar;		/* ��ʼ�뾶�仯ֵ */

		float fEndRadius;			/* �����뾶 */
		float fEndRadiusVar;		/* �����뾶�仯ֵ */

		float fSpinPerSecond;		/* ÿ����ת�Ƕ� */
		float fSpinPerSecondVar;	/* ÿ����ת�Ƕȱ仯ֵ */
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

		/* ���������� */

		Vec2 vEmitPos;				/* ������λ�� */
		Vec2 vEmitPosVar;			

		float fEmitAngle;			/* �������������ӽǶ� */
		float fEmitAngleVar;
				
		float fEmitSpeed;			/* ���������������ٶ� */
		float fEmitSpeedVar;

		int nParticleCount;			/* �������� */
		float fEmitRate;			/* ����ÿ�뷢������ */
		float fDuration;			/* ��������������ʱ�� */

		EmitterType emitterType;
		MotionMode  motionMode;

		/* �������� */

		/* ������������ */
		float fLife;
		float fLifeVar;

		/* ���ӵ���ɫ�仯 */
		Color cBeginColor;
		Color cBeginColorVar;
		Color cEndColor;
		Color cEndColorVar;

		/* ���ӵĴ�С�仯 */
		float fBeginSize;
		float fBeginSizeVar;
		float fEndSize;
		float fEndSizeVar;

		/* ������ת�Ƕȱ仯 */
		float fBeginSpin;
		float fBeginSpinVar;
		float fEndSpin;
		float fEndSpinVar;

		GravityMode gravityMode;
		RadiusMode radiusMode;
	};
}
