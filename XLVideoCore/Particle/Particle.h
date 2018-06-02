#pragma once
#include "ParticleDescription.h"

namespace XLSimple2D
{
	struct Particle
	{
		Vec2 vPos;
		Vec2 vChangePos;
		Vec2 vStartPos;

		Color cColor;
		Color cDeltaColor;

		float fCurrentSize;
		float fSize;
		float fDeltaSize;

		float fRotation;
		float fDeltaRotation;

		float fRemainingLife;

		/* ����ģʽ���� */
		struct GravityModeData
		{
			Vec2  vInitialVelocity;		/* ���ٶ� */
			float fRadialAccel;			/* ������ٶȣ�������ٶȣ��� ���˶�����ֱ */
			float fTangentialAccel;		/* ������ٶ� */

		} gravityMode;

		/* �뾶ģʽ���� */
		struct RadiusModeData
		{
			float fAngle;				/* ����Ƕ� */
			float fDegressPerSecond;	/* ÿ����ת�Ƕ� */
			float fRadius;				/* �뾶 */
			float fDelatRadius;			/* �뾶�仯�� */

		} radiusMode;
	};
}
